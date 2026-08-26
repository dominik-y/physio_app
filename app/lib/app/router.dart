import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/features/assignments/assign_flow_screen.dart';
import 'package:physio_app/features/home/patient_home_page.dart';
import 'package:physio_app/features/library/library_page.dart';
import 'package:physio_app/features/patients/patient_detail_page.dart';
import 'package:physio_app/features/patients/patients_page.dart';
import 'package:physio_app/features/role_gate/role_gate_page.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';
import 'package:physio_app/features/session/session_page.dart';
import 'package:physio_app/features/templates/templates_page.dart';

/// go_router stopped exporting this helper; authored locally. Bridges a
/// Stream (the RoleCubit's) to the Listenable go_router expects.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(RoleCubit roleCubit) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(roleCubit.stream),
    redirect: (context, state) {
      final role = roleCubit.state;
      final loc = state.matchedLocation;
      if (role == null) return loc == '/' ? null : '/';
      if (role == UserRole.physio && !loc.startsWith('/physio')) return '/physio/patients';
      if (role == UserRole.patient && !loc.startsWith('/patient/')) return '/patient/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const RoleGatePage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PhysioShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/physio/patients',
              builder: (context, state) => const PatientsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      PatientDetailPage(patientId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'assign',
                      builder: (context, state) =>
                          AssignFlowScreen(patientId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/physio/library',
              builder: (context, state) => const LibraryPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/physio/templates',
              builder: (context, state) => const TemplatesPage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/patient/home',
        builder: (context, state) => const PatientHomePage(),
      ),
      GoRoute(
        path: '/patient/session',
        builder: (context, state) => const SessionPage(),
      ),
    ],
  );
}

class PhysioShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const PhysioShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon: const Icon(Icons.people_rounded),
              label: AppLocalizations.of(context).navPatients),
          NavigationDestination(
              icon: const Icon(Icons.video_library_outlined),
              selectedIcon: const Icon(Icons.video_library_rounded),
              label: AppLocalizations.of(context).navLibrary),
          NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment_rounded),
              label: AppLocalizations.of(context).navTemplates),
        ],
      ),
    );
  }
}

/// Stand-in body until the feature pages are wired at integration.
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: Icons.construction_rounded,
        message: '$title is on its way',
        detail: 'This screen is wired at integration.',
      ),
      backgroundColor: AppColors.bg,
    );
  }
}
