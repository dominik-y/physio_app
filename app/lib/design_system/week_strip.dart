import 'package:flutter/material.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/design_system/tokens.dart';

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
