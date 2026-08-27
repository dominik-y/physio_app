import 'dart:async';

import 'package:physio_app/firebase/auth_identity.dart';
import 'package:physio_app/firebase/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ana = AuthIdentity(
  uid: 'uid-ana',
  isPhysio: false,
  patientId: 'pat-ana',
  displayName: 'Ana Kovačević',
);
const tomislav = AuthIdentity(
  uid: 'uid-physio',
  isPhysio: true,
  displayName: 'Tomislav Horvat',
);

class FakeAuthService implements AuthService {
  final _uids = StreamController<String?>.broadcast();
  String? uid;

  /// What resolveIdentity does next: an identity, or a failure to throw.
  /// Both are captured at call start, so tests can reconfigure the fake
  /// mid-flight to model a second account resolving while the first is
  /// still awaited.
  AuthIdentity? resolveResult;
  AuthFailure? resolveFailure;
  Duration resolveDelay = Duration.zero;
  int resolveCalls = 0;

  /// signIn outcome: null = success (fires the stream with [signInUid]).
  AuthFailure? signInResult;
  String signInUid = 'uid-physio';
  Duration signInDelay = Duration.zero;

  /// Unreachable-backend mode: signIn never completes (cubit timeout test).
  bool signInHangs = false;
  int signInCalls = 0;

  /// redeemInvite outcome (see method for the mid-flow stream behavior).
  AuthFailure? redeemResult;

  /// deleteAccount outcome: null = success (signs out via the stream).
  AuthFailure? deleteResult;

  void emitUid(String? value) {
    uid = value;
    _uids.add(value);
  }

  @override
  Stream<String?> uidChanges() => _uids.stream;

  @override
  String? get currentUid => uid;

  @override
  Future<AuthIdentity> resolveIdentity() async {
    final result = resolveResult;
    final failure = resolveFailure;
    final delay = resolveDelay;
    resolveCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (failure != null) throw AuthException(failure);
    return result!;
  }

  @override
  Future<void> signOut() async => emitUid(null);

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    if (signInHangs) return Completer<void>().future;
    if (signInDelay != Duration.zero) await Future<void>.delayed(signInDelay);
    if (signInResult != null) throw AuthException(signInResult!);
    emitUid(signInUid);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  /// The account-creation step always fires the auth stream mid-flow (the
  /// race the cubit must suppress); then either success, or invalidInvite
  /// with orphan cleanup (uid back to null).
  @override
  Future<void> redeemInvite(
      {required String code,
      required String email,
      required String password}) async {
    emitUid('uid-new');
    await Future<void>.delayed(Duration.zero);
    if (redeemResult != null) {
      if (redeemResult == AuthFailure.invalidInvite) emitUid(null);
      throw AuthException(redeemResult!);
    }
  }

  @override
  Future<void> redeemInviteForCurrentUser(String code) async {
    if (redeemResult != null) throw AuthException(redeemResult!);
  }

  @override
  Future<void> deleteAccount(String password) async {
    if (deleteResult != null) throw AuthException(deleteResult!);
    emitUid(null);
  }
}

Future<IdentityCache> freshCache() async {
  SharedPreferences.setMockInitialValues({});
  return IdentityCache(await SharedPreferences.getInstance());
}

Future<void> pump() => Future<void>.delayed(Duration.zero);
