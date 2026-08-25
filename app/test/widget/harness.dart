import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

/// Deterministic "today" for widget tests: a Tuesday morning matching the
/// core-test fixtures.
final testNow = DateTime(2026, 8, 25, 9, 30);

DemoStore seededStore() => DemoStore.seed(now: () => testNow);

const screenSizes = <Size>[
  Size(320, 568), // small phone — the overflow gauntlet
  Size(375, 667),
  Size(430, 932),
];

/// Pumps [page] inside the full provider stack at [size]. Render overflows
/// surface as test exceptions — never swallow them.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget page, {
  DemoStore? store,
  Size size = const Size(375, 667),
  UserRole role = UserRole.physio,
}) async {
  final s = store ?? seededStore();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final roleCubit = RoleCubit()..enterAs(role);
  addTearDown(roleCubit.close);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PatientsRepository>(create: (_) => DemoPatientsRepository(s)),
        RepositoryProvider<LibraryRepository>(create: (_) => DemoLibraryRepository(s)),
        RepositoryProvider<TemplatesRepository>(create: (_) => DemoTemplatesRepository(s)),
        RepositoryProvider<AssignmentsRepository>(create: (_) => DemoAssignmentsRepository(s)),
        RepositoryProvider<CompletionsRepository>(create: (_) => DemoCompletionsRepository(s)),
      ],
      child: BlocProvider.value(
        value: roleCubit,
        child: MaterialApp(theme: buildTheme(), home: page),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}
