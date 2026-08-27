import 'package:flutter/widgets.dart';
import 'package:physio_app/firebase/auth_service.dart' show AuthFailure;

/// What a real signed-in session offers the shared UI. Demo mode has none
/// (SessionScope carries null) — the role menu then shows the demo's
/// "switch role" instead of sign-out, and patient pages fall back to the
/// fixture patient. Callbacks are no-throw: failures come back as
/// [AuthFailure] for the caller to localize.
class AppSession {
  final String displayName;

  /// Resolved patients/{id} for a patient session; null for physios.
  final String? patientId;
  final Future<void> Function() signOut;

  /// Present only for patient sessions (App Store 5.1.1(v)); takes the
  /// password for reauthentication, null result = success.
  final Future<AuthFailure?> Function(String password)? deleteAccount;

  const AppSession({
    required this.displayName,
    this.patientId,
    required this.signOut,
    this.deleteAccount,
  });
}

class SessionScope extends InheritedWidget {
  final AppSession? session;

  const SessionScope({super.key, this.session, required super.child});

  static AppSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()?.session;

  @override
  bool updateShouldNotify(SessionScope oldWidget) =>
      session != oldWidget.session;
}
