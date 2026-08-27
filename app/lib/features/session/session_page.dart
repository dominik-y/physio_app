import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/demo_video_player.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/session/session_bloc.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

const _sessionBg = AppColors.videoBg;

/// Full-screen guided session player (spec §5.2). Dark regardless of the
/// app theme — the player is a focused, distraction-free space.
class SessionPage extends StatelessWidget {
  /// Null resolves via SessionScope (Firebase flavor), falling back to the
  /// demo fixture patient.
  final String? patientId;

  /// Clock override so tests can pin "today" to the seeded fixture date.
  final NowFn? now;

  const SessionPage({super.key, this.patientId, this.now});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SessionBloc(
        patientId: patientId ??
            SessionScope.maybeOf(context)?.patientId ??
            DemoData.currentPatientId,
        assignmentsRepository: context.read<AssignmentsRepository>(),
        completionsRepository: context.read<CompletionsRepository>(),
        now: now ?? DateTime.now,
      )..add(const SessionStarted()),
      child: const _SessionScaffold(),
    );
  }
}

class _SessionScaffold extends StatelessWidget {
  const _SessionScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sessionBg,
      body: SafeArea(
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            return switch (state) {
              SessionLoading() => const SizedBox.expand(),
              SessionEmpty() => const _EmptyBody(),
              SessionInProgress() => _InProgressBody(state: state),
              SessionComplete() => _CompleteBody(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          tooltip: AppLocalizations.of(context).close,
          icon: const Icon(Icons.close_rounded, color: AppColors.onAccent),
        ),
      ],
    );
  }
}

class _InProgressBody extends StatelessWidget {
  final SessionInProgress state;

  const _InProgressBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exercise = state.current;
    final item = exercise.item;

    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(left: 4), child: _CloseButton()),
        // The video fills all leftover height — it is the dominant object
        // (spec §5.2: the screen is mostly video), with meta pinned below it.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: DemoVideoPlayer(
                          key: ValueKey(item.videoId),
                          title: item.title,
                          bodyPart: item.bodyPart,
                          durationSec: item.durationSec,
                          videoId: item.videoId,
                          mediaUrl: item.mediaUrl,
                          autoplay: true,
                          fill: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.exerciseNofM(state.currentIndex + 1, state.total),
                  style: const TextStyle(
                    color: AppColors.accentSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.onAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    DosagePill(label: l.setsPill, value: '${item.sets}'),
                    DosagePill(label: l.repsPill, value: '${item.reps}'),
                    if (item.holdSec > 0)
                      DosagePill(label: l.holdPill, value: '${item.holdSec}s'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          // Same max width as the video column — a full-bleed control bar
          // under a centered video reads as broken on desktop.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  PrimaryButton(
                    label: l.doneNextExercise,
                    background: AppColors.onAccent,
                    foreground: AppColors.accentDeep,
                    onPressed: () =>
                        context.read<SessionBloc>().add(const DonePressed()),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        context.read<SessionBloc>().add(const SkipPressed()),
                    // warning is 3.2:1 on the dark stage; warningOnDark is 7.7:1.
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.warningOnDark),
                    child: Text(l.skipThisOne,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompleteBody extends StatelessWidget {
  final SessionComplete state;

  const _CompleteBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(left: 4), child: _CloseButton()),
        Expanded(
          // Upper-middle third — where the eye already is after the last tap.
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.accentSoft, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    l.sessionComplete,
                    style: const TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.doneSkippedSummary(state.doneCount, state.skippedCount),
                    style: TextStyle(
                        color: AppColors.onAccent.withOpacity(0.7),
                        fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: l.backToHome,
                    background: AppColors.onAccent,
                    foreground: AppColors.accentDeep,
                    onPressed: () => context.go('/patient/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(left: 4), child: _CloseButton()),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa_rounded,
                      size: 44, color: AppColors.onAccent.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text(
                    l.nothingDueToday,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: l.backToHome,
                    background: AppColors.onAccent,
                    foreground: AppColors.accentDeep,
                    onPressed: () => context.go('/patient/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
