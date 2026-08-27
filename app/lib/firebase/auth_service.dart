import 'package:physio_app/firebase/auth_identity.dart';

/// Typed auth failures — the UI maps these to Croatian strings; nothing
/// downstream ever inspects FirebaseAuthException codes directly.
enum AuthFailure {
  /// Wrong email/password on sign-in.
  invalidCredentials,

  /// Redemption: the email already has an account and the entered password
  /// doesn't match it (the sign-in fallback of plan correction #4 failed).
  emailInUseWrongPassword,

  /// Invite code unknown, redeemed, or expired — the rules deny the read
  /// and the client can't tell which, by design.
  invalidInvite,

  /// Signed in but no patient doc carries this uid and no physio claim —
  /// an interrupted redemption; recoverable by re-entering the code.
  notLinked,

  weakPassword,
  invalidEmail,
  network,

  /// Account deletion refused a stale session even after reauth.
  requiresRecentLogin,
  unknown,
}

class AuthException implements Exception {
  final AuthFailure failure;
  const AuthException(this.failure);

  @override
  String toString() => 'AuthException(${failure.name})';
}

/// Everything the gate UI needs from Firebase Auth + Firestore, expressed
/// without Firebase types so the cubit and screens are plugin-free testable.
abstract class AuthService {
  /// Emits the signed-in uid, null when signed out. Fires immediately with
  /// the current state on subscribe (FirebaseAuth semantics).
  Stream<String?> uidChanges();

  String? get currentUid;

  /// Throws [AuthException] (invalidCredentials, invalidEmail, network).
  Future<void> signIn(String email, String password);

  Future<void> sendPasswordReset(String email);

  /// The full "Imam pozivni kod" flow (plan correction #4):
  /// create the account (falling back to sign-in when the email already
  /// exists), then redeem [code] as a rules-validated 2-doc batch. If the
  /// code is invalid and the account was created by THIS call, the orphan
  /// Auth user is deleted before rethrowing.
  Future<void> redeemInvite({
    required String code,
    required String email,
    required String password,
  });

  /// Redemption for an already-authed but unlinked account ([AuthFailure
  /// .notLinked] recovery — e.g. app killed between account creation and
  /// the redemption batch).
  Future<void> redeemInviteForCurrentUser(String code);

  /// Resolves the signed-in user to physio (custom claim) or patient
  /// (patients query by uid). Network-dependent; throws so the caller can
  /// fall back to [IdentityCache].
  Future<AuthIdentity> resolveIdentity();

  /// Reauthenticates with [password], then deletes the Auth account
  /// (App Store 5.1.1(v) minimal compliance).
  Future<void> deleteAccount(String password);

  Future<void> signOut();
}
