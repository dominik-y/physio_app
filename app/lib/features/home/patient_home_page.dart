import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/role_menu.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/hero_card.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/home/patient_home_bloc.dart';
import 'package:physio_app/features/home/single_video_page.dart';
import 'package:physio_app/l10n/body_parts.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Patient home (spec §5.1): one screen, no tabs. Hero anchors the top,
/// "Also assigned" singles below it, body-part sections last.
class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.maybeOf(context);
    return BlocProvider(
      create: (context) => PatientHomeBloc(
        assignmentsRepository: context.read<AssignmentsRepository>(),
        completionsRepository: context.read<CompletionsRepository>(),
        patientsRepository: context.read<PatientsRepository>(),
        patientId: session?.patientId ?? DemoData.currentPatientId,
      ),
      child: const _PatientHomeView(),
    );
  }
}

String _greeting(AppLocalizations l, DateTime now) {
  final h = now.hour;
  if (h < 12) return l.goodMorning;
  if (h < 18) return l.goodAfternoon;
  return l.goodEvening;
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
            final l = AppLocalizations.of(context);
            final name = state.patientName.isEmpty
                ? (SessionScope.maybeOf(context)?.displayName ??
                    DemoData.currentPatientName)
                : state.patientName;
            return ContentColumn(
                child: ListView(
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
                            _greeting(l, DateTime.now()),
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
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.spa_outlined,
                      message: l.nothingAssignedYet,
                      detail: l.physioWillSetYouUp,
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
                    SectionHeader(title: l.alsoAssigned),
                    ...state.singles.map((s) => _SingleRow(row: s)),
                  ],
                  for (final section in state.bodyPartSections) ...[
                    SectionHeader(
                        title: localizedBodyPart(l, section.bodyPart)),
                    ...section.items.map((item) => _ExerciseRow(item: item)),
                  ],
                  if (state.heroState == HeroState.done) ...[
                    const SizedBox(height: AppSpacing.xl),
                    // Soft anchor: the finished screen ends on purpose.
                    Center(
                      child: Text(
                        l.everythingDoneToday,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ],
              ],
            ));
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
          context
              .read<PatientHomeBloc>()
              .add(AssignmentOpened(row.assignmentId));
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => SingleVideoPage(
                title: row.title,
                bodyPart: row.bodyPart,
                durationSec: row.durationSec,
                videoId: row.videoId,
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
        // Browse-only preview; completions are recorded in the guided
        // session, not here (§4.6 amendment 3).
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => SingleVideoPage(
              title: item.title,
              bodyPart: item.bodyPart,
              durationSec: item.durationSec,
              videoId: item.videoId,
            ),
          ),
        ),
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
                    AppLocalizations.of(context)
                        .setsTimesReps(item.sets, item.reps),
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
