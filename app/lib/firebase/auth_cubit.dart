import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/firebase/auth_identity.dart';
import 'package:physio_app/firebase/auth_service.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Before the first uidChanges event lands — splash.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// Signed in, no cached identity, resolution in flight — splash.
class AuthResolving extends AuthState {
  const AuthResolving();
}

/// Signed in but identity resolution failed and nothing was cached.
/// [AuthFailure.notLinked] routes to invite re-entry; anything else offers
/// retry / sign out.
class AuthResolveFailed extends AuthState {
  final AuthFailure failure;
  const AuthResolveFailed(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// The app runs. [identity] may come straight from cache (offline cold
/// start); a background refresh replaces it when resolution succeeds.
class AuthReady extends AuthState {
  final AuthIdentity identity;
  const AuthReady(this.identity);

  @override
  List<Object?> get props => [identity];
}

/// Cache-first identity resolution over the auth stream (plan correction
/// #3): a cached identity boots the app instantly — even offline with an
/// expired token — and the network refresh corrects it in the background.
class AuthCubit extends Cubit<AuthState> {
  final AuthService _service;
  final IdentityCache _cache;
  late final StreamSubscription<String?> _sub;

  /// Redemption is multi-step (create user → link batch): the auth stream
  /// fires after step 1 and identity resolution at that instant would flash
  /// AuthResolveFailed(notLinked). Suppressed until the flow settles.
  bool _suppressStream = false;

  AuthCubit(this._service, this._cache) : super(const AuthUnknown()) {
    _sub = _service.uidChanges().listen(_onUid);
  }

  Future<void> _onUid(String? uid) async {
    if (_suppressStream) return;
    if (uid == null) {
      // Externally-driven sign-outs (token revoked, account disabled) must
      // not leave the previous user's identity on disk — shared clinic
      // devices inherit prefs.
      await _cache.clear();
      if (isClosed) return;
      emit(const AuthSignedOut());
      return;
    }
    final cached = _cache.read(uid);
    if (cached != null) {
      emit(AuthReady(cached));
      await _refresh(uid);
      return;
    }
    emit(const AuthResolving());
    await _refresh(uid);
  }

  /// True once a resolution launched for [uid] no longer speaks for the
  /// current session — the account changed mid-flight, or the cubit closed.
  /// A stale success must neither emit nor repoison the cache.
  bool _stale(String uid) => isClosed || _service.currentUid != uid;

  Future<void> _refresh(String uid) async {
    try {
      final identity = await _service.resolveIdentity();
      if (_stale(uid) || identity.uid != uid) return;
      await _cache.write(identity);
      if (_stale(uid)) return;
      if (state is AuthReady || state is AuthResolving) {
        emit(AuthReady(identity));
      }
    } on AuthException catch (e) {
      if (_stale(uid)) return;
      // With a cached identity the app is already running — stay on cache
      // unless the backend positively says this account has no link.
      if (state is AuthReady && e.failure != AuthFailure.notLinked) return;
      emit(AuthResolveFailed(e.failure));
    } catch (_) {
      // A malformed doc must land on the retry screen, not freeze the
      // splash forever with an uncaught async error.
      if (_stale(uid)) return;
      emit(const AuthResolveFailed(AuthFailure.unknown));
    }
  }

  /// Retry after AuthResolveFailed (e.g. network came back).
  Future<void> retryResolve() async {
    final uid = _service.currentUid;
    if (uid == null) return;
    emit(const AuthResolving());
    await _refresh(uid);
  }

  /// No-throw command surface for the gate screens: null = success,
  /// otherwise the failure to localize. State transitions ride the auth
  /// stream for plain sign-in.
  Future<AuthFailure?> signIn(String email, String password) async {
    try {
      await _service.signIn(email, password);
      return null;
    } on AuthException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
      return null;
    } on AuthException catch (e) {
      return e.failure;
    }
  }

  /// The "Imam pozivni kod" flow, stream-suppressed end to end.
  Future<AuthFailure?> redeemInvite({
    required String code,
    required String email,
    required String password,
  }) async {
    _suppressStream = true;
    try {
      await _service.redeemInvite(code: code, email: email, password: password);
      final uid = _service.currentUid;
      if (uid == null) return AuthFailure.unknown;
      emit(const AuthResolving());
      await _refresh(uid);
      return null;
    } on AuthException catch (e) {
      return e.failure;
    } finally {
      _suppressStream = false;
      _resyncWithAuth();
    }
  }

  /// Events swallowed during suppression are gone — replay reality so the
  /// cubit can't stay AuthSignedOut over a live session (e.g. account
  /// created but the link batch died on the network: the user must land on
  /// the notLinked recovery screen, not a dead login form).
  void _resyncWithAuth() {
    if (isClosed) return;
    final uid = _service.currentUid;
    if (uid == null) {
      if (state is! AuthSignedOut && state is! AuthUnknown) {
        emit(const AuthSignedOut());
      }
    } else if (state is AuthSignedOut || state is AuthUnknown) {
      unawaited(_onUid(uid));
    }
  }

  /// Redemption for the notLinked recovery screen (already signed in).
  Future<AuthFailure?> redeemForCurrentUser(String code) async {
    try {
      await _service.redeemInviteForCurrentUser(code);
      final uid = _service.currentUid;
      if (uid == null) return AuthFailure.unknown;
      emit(const AuthResolving());
      await _refresh(uid);
      return null;
    } on AuthException catch (e) {
      return e.failure;
    }
  }

  // DEFERRED (shared clinic devices): Firestore's local persistence is not
  // wiped here — clearPersistence() requires terminate() first, which kills
  // the cached FirebaseFirestore instance for the rest of the process and
  // would break sign-in-after-sign-out. Needs the day-9 on-device offline
  // drills to land safely; until then a signed-out device retains the
  // previous user's Firestore cache (unreadable in-app, but on disk).
  Future<void> signOut() async {
    await _cache.clear();
    await _service.signOut();
  }

  /// AppSession.deleteAccount shape: null = success (the auth stream then
  /// lands the app on the signed-out gate).
  Future<AuthFailure?> deleteAccount(String password) async {
    try {
      await _service.deleteAccount(password);
      await _cache.clear();
      return null;
    } on AuthException catch (e) {
      return e.failure;
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
