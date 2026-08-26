import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/locale_cubit.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/app/router.dart';
import 'package:physio_app/data/demo_media_store.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/domain/repository_bundle.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhysioApp extends StatefulWidget {
  /// Injectable for tests; defaults to a freshly seeded store. Ignored when
  /// [repositories] is provided.
  final DemoStore? store;

  /// Flavor seam: the Firebase entrypoint passes its own bundle; null means
  /// demo mode (in-memory, seeded) — the default and the pitch build.
  final RepositoryBundle? repositories;

  /// Locale persistence; null (tests) means the choice lives for the session.
  final SharedPreferences? prefs;

  const PhysioApp({super.key, this.store, this.repositories, this.prefs});

  @override
  State<PhysioApp> createState() => _PhysioAppState();
}

class _PhysioAppState extends State<PhysioApp> {
  late final RepositoryBundle _repositories = widget.repositories ??
      demoRepositoryBundle(widget.store ?? DemoStore.seed());

  @override
  void initState() {
    super.initState();
    // Seeded real footage: Tendo's own reel plays for the library entry.
    DemoMediaStore.instance
        .register('v-tendo-drill', 'asset:assets/videos/tendo_reel8.mp4');
  }
  late final RoleCubit _roleCubit = RoleCubit();
  late final LocaleCubit _localeCubit = LocaleCubit(prefs: widget.prefs);
  late final GoRouter _router = buildRouter(_roleCubit);

  @override
  void dispose() {
    _roleCubit.close();
    _localeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PatientsRepository>(create: (_) => _repositories.patients),
        RepositoryProvider<LibraryRepository>(create: (_) => _repositories.library),
        RepositoryProvider<TemplatesRepository>(create: (_) => _repositories.templates),
        RepositoryProvider<AssignmentsRepository>(create: (_) => _repositories.assignments),
        RepositoryProvider<CompletionsRepository>(create: (_) => _repositories.completions),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _roleCubit),
          BlocProvider.value(value: _localeCubit),
        ],
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) => MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            locale: locale,
            supportedLocales: LocaleCubit.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
