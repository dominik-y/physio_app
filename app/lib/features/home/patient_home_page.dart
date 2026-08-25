import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/role_menu.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/hero_card.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/home/patient_home_bloc.dart';
import 'package:physio_app/features/home/single_video_page.dart';

/// Patient home (spec §5.1): one screen, no tabs. Hero anchors the top,
/// "Also assigned" singles below it, body-part sections last.
class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientHomeBloc(
        assignmentsRepository: context.read<AssignmentsRepository>(),
        completionsRepository: context.read<CompletionsRepository>(),
        patientsRepository: context.read<PatientsRepository>(),
      ),
      child: const _PatientHomeView(),
    );
  }
}

String _greeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

class _PatientHomeView extends StatelessWidget {
  const _PatientHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<PatientHomeBloc, PatientHomeState>(
          builder: (context, state) {
            final name = state.patientName.isEmpty ? DemoData.currentPatientName : state.patientName;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(DateTime.now()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    RoleMenuButton(name: name),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (!state.hasAnyAssignment)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.spa_outlined,
                      message: 'Nothing assigned yet',
                      detail: 'Your physio will set you up.',
                    ),
                  )
                else ...[
                  SessionHeroCard(
                    state: state.heroState,
                    totalExercises: state.totalExercises,
                    remaining: state.remaining,
                    protocolNames: state.protocolNames,
                    weekMarks: state.weekMarks,
                    showNew: state.showNew,
                    onStart: () => context.push('/patient/session'),
                  ),
                  if (state.singles.isNotEmpty) ...[
                    const SectionHeader(title: 'Also assigned'),
                    ...state.singles.map((s) => _SingleRow(row: s)),
                  ],
                  for (final section in state.bodyPartSections) ...[
                    SectionHeader(title: section.bodyPart),
                    ...section.items.map((item) => _ExerciseRow(item: item)),
                  ],
                  if (state.heroState == HeroState.done) ...[
                    const SizedBox(height: AppSpacing.xl),
                    // Soft anchor: the finished screen ends on purpose.
                    const Center(
                      child: Text(
                        'That’s everything for today — see you tomorrow.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SingleRow extends StatelessWidget {
  final SingleAssignmentRow row;
  const _SingleRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () {
          context.read<PatientHomeBloc>().add(AssignmentOpened(row.assignmentId));
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => SingleVideoPage(
                title: row.title,
                bodyPart: row.bodyPart,
                durationSec: row.durationSec,
              ),
            ),
          );
        },
        child: Row(
          children: [
            VideoThumb(bodyPart: row.bodyPart),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    formatDuration(row.durationSec),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!row.seen) ...[
              const SizedBox(width: AppSpacing.sm),
              const StatusChip.newBadge(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExerciseItem item;
  const _ExerciseRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            VideoThumb(bodyPart: item.bodyPart),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${item.sets}× ${item.reps} reps',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
