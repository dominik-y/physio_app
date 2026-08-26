import 'package:flutter/material.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/design_system/week_strip.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

enum HeroState { start, resume, done, empty }

/// The patient home anchor (spec §5.1): one dark pine card, one action.
class SessionHeroCard extends StatelessWidget {
  final HeroState state;
  final int totalExercises;
  final int remaining;
  final List<String> protocolNames;
  final List<DayMark> weekMarks;
  final bool showNew;
  final VoidCallback? onStart;

  const SessionHeroCard({
    super.key,
    required this.state,
    required this.totalExercises,
    required this.remaining,
    required this.protocolNames,
    required this.weekMarks,
    this.showNew = false,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final headline = switch (state) {
      HeroState.start => l.exercisesCount(totalExercises),
      HeroState.resume => l.remainingCount(remaining),
      HeroState.done => l.sessionComplete,
      HeroState.empty => l.nothingDueToday,
    };
    final cta = switch (state) {
      HeroState.start => l.startTodaysSession,
      HeroState.resume => l.resumeSession,
      HeroState.done => l.doneForToday,
      HeroState.empty => null,
    };

    // Explicit label: the web engine drops this subtree's text semantics
    // otherwise, leaving screen readers with an unlabeled group.
    final semanticSummary = [
      l.todaysSessionSemantic(headline),
      if (protocolNames.isNotEmpty) protocolNames.join(', '),
      if (showNew) l.newAssignment,
    ].join('. ');

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.card + 3),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: semanticSummary,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
            children: [
              Expanded(
                child: Text(
                  l.todaysSessionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.accentSoft,
                  ),
                ),
              ),
              if (showNew) const StatusChip.newBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onAccent,
                    height: 1.15,
                  ),
                ),
              ),
              if (state == HeroState.done)
                const Icon(Icons.check_circle_rounded, color: AppColors.onAccent, size: 28),
            ],
          ),
                  if (protocolNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      protocolNames.join(' · '),
                      // Two protocols must both be visible at 320px.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 14, color: AppColors.onAccent.withOpacity(0.72)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  WeekStrip(marks: weekMarks, dotSize: 10, onDark: true),
                ],
              ),
            ),
          ),
          if (cta != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              enabled: state != HeroState.done,
              label: cta,
              onTap: state == HeroState.done ? null : onStart,
              child: ExcludeSemantics(
                child: PrimaryButton(
                  label: cta,
                  onPressed: state == HeroState.done ? null : onStart,
                  background: AppColors.onAccent,
                  foreground: AppColors.accentDeep,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
