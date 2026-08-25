import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/app/router.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/repositories.dart';

class PhysioApp extends StatefulWidget {
  /// Injectable for tests; defaults to a freshly seeded store.
  final DemoStore? store;

  const PhysioApp({super.key, this.store});

  @override
  State<PhysioApp> createState() => _PhysioAppState();
}

class _PhysioAppState extends State<PhysioApp> {
  late final DemoStore _store = widget.store ?? DemoStore.seed();
  late final RoleCubit _roleCubit = RoleCubit();
  late final GoRouter _router = buildRouter(_roleCubit);

  @override
  void dispose() {
    _roleCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PatientsRepository>(create: (_) => DemoPatientsRepository(_store)),
        RepositoryProvider<LibraryRepository>(create: (_) => DemoLibraryRepository(_store)),
        RepositoryProvider<TemplatesRepository>(create: (_) => DemoTemplatesRepository(_store)),
        RepositoryProvider<AssignmentsRepository>(create: (_) => DemoAssignmentsRepository(_store)),
        RepositoryProvider<CompletionsRepository>(create: (_) => DemoCompletionsRepository(_store)),
      ],
      child: BlocProvider.value(
        value: _roleCubit,
        child: MaterialApp.router(
          title: 'Poliklinika Tendo',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
