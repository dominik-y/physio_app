import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/app.dart';
import 'package:physio_app/app/locale_cubit.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repository_bundle.dart';
import 'package:physio_app/firebase/auth_cubit.dart';
import 'package:physio_app/firebase/auth_identity.dart';
import 'package:physio_app/firebase/auth_service.dart';
import 'package:physio_app/firebase/gate/auth_gate.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Root of the Firebase flavor: swaps between the auth gate and the real
/// app as AuthCubit's state moves. [bundleBuilder] keeps Firestore types
/// out of here so widget tests can drive the whole gate with fakes.
class TendoFirebaseApp extends StatefulWidget {
  final AuthService service;
  final SharedPreferences prefs;
  final RepositoryBundle Function(AuthIdentity identity) bundleBuilder;

  /// Real upload pipeline + 90 s clip cap; null (gate widget tests) keeps
  /// the sheet in demo simulation.
  final MediaConfig? mediaConfig;

  const TendoFirebaseApp({
    super.key,
    required this.service,
    required this.prefs,
    required this.bundleBuilder,
    this.mediaConfig,
  });

  @override
  State<TendoFirebaseApp> createState() => _TendoFirebaseAppState();
}

class _TendoFirebaseAppState extends State<TendoFirebaseApp> {
  late final AuthCubit _auth =
      AuthCubit(widget.service, IdentityCache(widget.prefs));

  // Repositories hold live Firestore streams — rebuild them only when the
  // account (not just the display name) changes.
  RepositoryBundle? _bundle;
  String? _bundleKey;

  RepositoryBundle _bundleFor(AuthIdentity identity) {
    final key = '${identity.uid}|${identity.isPhysio}';
    if (_bundleKey != key) {
      _bundle = widget.bundleBuilder(identity);
      _bundleKey = key;
    }
    return _bundle!;
  }

  @override
  void dispose() {
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _auth,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) => switch (state) {
          AuthReady(:final identity) => PhysioApp(
              key: ValueKey('session-${identity.uid}'),
              prefs: widget.prefs,
              repositories: _bundleFor(identity),
              initialRole:
                  identity.isPhysio ? UserRole.physio : UserRole.patient,
              mediaConfig: widget.mediaConfig,
              session: AppSession(
                displayName: identity.displayName,
                patientId: identity.patientId,
                signOut: _auth.signOut,
                deleteAccount: identity.isPhysio ? null : _auth.deleteAccount,
              ),
            ),
          AuthSignedOut() => _gate(const SignedOutFlow()),
          AuthResolveFailed(:final failure) => _gate(
              failure == AuthFailure.notLinked
                  ? const InviteScreen()
                  : ResolveErrorScreen(failure: failure)),
          AuthUnknown() || AuthResolving() => _gate(const GateSplash()),
        },
      ),
    );
  }

  Widget _gate(Widget child) {
    // Fresh cubit per gate entry: PhysioApp runs its own LocaleCubit over
    // the same prefs, so a locale toggled inside the app must be re-read
    // when the user signs out back to the gate.
    return BlocProvider(
      create: (_) => LocaleCubit(prefs: widget.prefs),
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: locale,
          supportedLocales: LocaleCubit.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      ),
    );
  }
}
