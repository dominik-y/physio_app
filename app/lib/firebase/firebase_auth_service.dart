import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physio_app/firebase/auth_identity.dart';
import 'package:physio_app/firebase/auth_service.dart';

/// The only class that touches FirebaseAuth directly — everything above it
/// (cubit, screens) speaks [AuthService] and is tested with a fake.
/// Exercised for real by e2e/scripts/auth-smoke.mjs against the emulator.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseAuthService(this._auth, this._db);

  @override
  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthCode(e.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Don't leak which emails exist: swallow user-not-found.
      if (e.code == 'user-not-found') return;
      throw AuthException(_mapAuthCode(e.code));
    }
  }

  @override
  Future<void> redeemInvite({
    required String code,
    required String email,
    required String password,
  }) async {
    var createdHere = false;
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      createdHere = true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') {
        throw AuthException(_mapAuthCode(e.code));
      }
      // Plan correction #4: existing account retrying redemption — sign in
      // with the entered password and continue to the batch.
      try {
        await _auth.signInWithEmailAndPassword(
            email: email.trim(), password: password);
      } on FirebaseAuthException catch (e2) {
        throw AuthException(
            e2.code == 'wrong-password' || e2.code == 'invalid-credential'
                ? AuthFailure.emailInUseWrongPassword
                : _mapAuthCode(e2.code));
      }
    }
    try {
      await redeemInviteForCurrentUser(code);
    } on AuthException catch (e) {
      // Orphan cleanup: an account we just created that never got linked
      // would block this email forever ("email-already-in-use" with no
      // patient behind it). Best-effort — a failure here still surfaces
      // the original invite error.
      if (createdHere && e.failure == AuthFailure.invalidInvite) {
        try {
          await _auth.currentUser?.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<void> redeemInviteForCurrentUser(String code) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException(AuthFailure.unknown);
    final normalized = normalizeInviteCode(code);
    if (normalized.isEmpty) {
      throw const AuthException(AuthFailure.invalidInvite);
    }

    // Idempotence: a retry after a successful batch (app killed mid-flow)
    // finds the link and is simply done.
    if ((await _linkedPatients(uid)).docs.isNotEmpty) return;

    final inviteRef = _db.collection('invites').doc(normalized);
    final DocumentSnapshot<Map<String, dynamic>> invite;
    try {
      invite = await inviteRef.get();
    } on FirebaseException catch (e) {
      // Rules deny reads of redeemed/expired invites — indistinguishable
      // from a wrong code, by design.
      throw AuthException(e.code == 'permission-denied'
          ? AuthFailure.invalidInvite
          : _mapFirestoreCode(e.code));
    }
    final patientId = invite.data()?['patientId'] as String?;
    if (patientId == null) throw const AuthException(AuthFailure.invalidInvite);

    final batch = _db.batch()
      ..update(inviteRef, {
        'redeemed': true,
        'redeemedBy': uid,
        'redeemedAt': FieldValue.serverTimestamp(),
      })
      ..update(_db.collection('patients').doc(patientId), {'uid': uid});
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // permission-denied here = lost a race (someone redeemed between our
      // read and the commit) or a stale code — same message to the user.
      throw AuthException(e.code == 'permission-denied'
          ? AuthFailure.invalidInvite
          : _mapFirestoreCode(e.code));
    }
  }

  @override
  Future<AuthIdentity> resolveIdentity() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(AuthFailure.unknown);
    final IdTokenResult token;
    try {
      // Refreshes an expired token; offline this throws → cubit falls back
      // to the cached identity (plan correction #3).
      token = await user.getIdTokenResult();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthCode(e.code));
    } catch (_) {
      throw const AuthException(AuthFailure.network);
    }
    if (token.claims?['role'] == 'physio') {
      var name = user.email ?? '';
      try {
        final doc = await _db.collection('physios').doc(user.uid).get();
        final n = doc.data()?['name'] as String?;
        if (n != null && n.isNotEmpty) name = n;
      } on FirebaseException catch (_) {
        // Email is a fine fallback; don't fail resolution over a name.
      }
      return AuthIdentity(uid: user.uid, isPhysio: true, displayName: name);
    }
    final q = await _linkedPatients(user.uid);
    if (q.docs.isEmpty) {
      // An empty answer served from the LOCAL CACHE proves nothing (fresh
      // reinstall, evicted cache) — only the server may declare notLinked,
      // because notLinked evicts the cached identity and ejects the user.
      throw AuthException(
          q.metadata.isFromCache ? AuthFailure.network : AuthFailure.notLinked);
    }
    final link = q.docs.first;
    return AuthIdentity(
      uid: user.uid,
      isPhysio: false,
      patientId: link.id,
      displayName: (link.data()['name'] as String?) ?? '',
    );
  }

  @override
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(
          email: user.email ?? '', password: password));
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
          e.code == 'wrong-password' || e.code == 'invalid-credential'
              ? AuthFailure.invalidCredentials
              : _mapAuthCode(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<QuerySnapshot<Map<String, dynamic>>> _linkedPatients(
      String uid) async {
    try {
      return await _db
          .collection('patients')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreCode(e.code));
    }
  }
}

/// Uppercases and reformats whatever the patient typed into the canonical
/// dashed form that IS the invite doc ID: "lk73fq9" → "LK7-3FQ9".
String normalizeInviteCode(String raw) {
  final chars = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '').split('');
  if (chars.length != 7) return raw.trim().toUpperCase();
  return '${chars.sublist(0, 3).join()}-${chars.sublist(3).join()}';
}

AuthFailure _mapAuthCode(String code) => switch (code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'user-disabled' =>
        AuthFailure.invalidCredentials,
      'invalid-email' => AuthFailure.invalidEmail,
      'weak-password' => AuthFailure.weakPassword,
      'network-request-failed' => AuthFailure.network,
      'requires-recent-login' => AuthFailure.requiresRecentLogin,
      _ => AuthFailure.unknown,
    };

AuthFailure _mapFirestoreCode(String code) => switch (code) {
      'unavailable' || 'deadline-exceeded' => AuthFailure.network,
      _ => AuthFailure.unknown,
    };
