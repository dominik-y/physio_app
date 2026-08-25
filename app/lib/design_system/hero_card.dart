import 'package:flutter/material.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/design_system/week_strip.dart';

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
    final headline = switch (state) {
      HeroState.start => '$totalExercises exercise${totalExercises == 1 ? '' : 's'}',
      HeroState.resume => '$remaining remaining',
      HeroState.done => 'Session complete',
      HeroState.empty => 'Nothing due today',
    };
    final cta = switch (state) {
      HeroState.start => 'Start today’s session',
      HeroState.resume => 'Resume session',
      HeroState.done => 'Done for today',
      HeroState.empty => null,
    };

    // Explicit label: the web engine drops this subtree's text semantics
    // otherwise, leaving screen readers with an unlabeled group.
    final semanticSummary = [
      'Today’s session: $headline',
      if (protocolNames.isNotEmpty) protocolNames.join(', '),
      if (showNew) 'New assignment',
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
              const Expanded(
                child: Text(
                  'TODAY’S SESSION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                      maxLines: 1,
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
