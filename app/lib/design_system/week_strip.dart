import 'package:flutter/material.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Seven dots, oldest first, last dot = today (spec §6.1).
/// Filled accent = completed · amber = skipped · outline = nothing.
class WeekStrip extends StatelessWidget {
  final List<DayMark> marks;
  final double dotSize;
  final bool onDark;

  const WeekStrip({super.key, required this.marks, this.dotSize = 9, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < marks.length; i++) ...[
            if (i > 0) SizedBox(width: dotSize * 0.55),
            _Dot(mark: marks[i], size: dotSize, onDark: onDark),
          ],
        ],
      ),
    );
  }
}

/// One-line key for the week strip (owner asked twice what the dots mean —
/// nobody in the room should have to). Light theme only.
class WeekStripLegend extends StatelessWidget {
  const WeekStripLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget entry(DayMark mark, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(mark: mark, size: 8, onDark: false),
            const SizedBox(width: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
        );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: 4,
      children: [
        entry(DayMark.done, l.legendDone),
        entry(DayMark.skipped, l.legendSkipped),
        entry(DayMark.empty, l.legendMissed),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final DayMark mark;
  final double size;
  final bool onDark;

  const _Dot({required this.mark, required this.size, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final emptyBorder = onDark ? AppColors.onAccent.withOpacity(0.4) : AppColors.border;
    final doneFill = onDark ? AppColors.onAccent : AppColors.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (mark) {
          DayMark.done => doneFill,
          DayMark.skipped => AppColors.warning,
          DayMark.empty => Colors.transparent,
        },
        border: mark == DayMark.empty ? Border.all(color: emptyBorder, width: 1.3) : null,
      ),
    );
  }
}
