import 'package:flutter/material.dart';
import 'package:physio_app/design_system/tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // surface and bg are near-identical in luminance; a soft warm shadow is
    // what makes rows read as tappable cards rather than ruled regions.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final Color background;
  final Color foreground;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = true,
    this.background = AppColors.accent,
    this.foreground = AppColors.onAccent,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withOpacity(0.4),
        disabledForegroundColor: foreground.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  const SecondaryButton({super.key, required this.label, this.onPressed, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentDeep,
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Sets / reps / hold pill. [overridden] renders outlined in accent —
/// "bespoke for this patient" (spec §6.3).
class DosagePill extends StatelessWidget {
  final String label;
  final String value;
  final bool overridden;
  final VoidCallback? onTap;

  const DosagePill({
    super.key,
    required this.label,
    required this.value,
    this.overridden = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: overridden ? AppColors.surface : AppColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        side: BorderSide(
          color: overridden ? AppColors.accent : AppColors.border,
          width: overridden ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: overridden ? AppColors.accentDeep : AppColors.text,
                  )),
              Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChipVariant { invited, private, newBadge, warning, danger }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipVariant variant;

  const StatusChip({super.key, required this.label, required this.variant});

  const StatusChip.invited({super.key})
      : label = 'invited',
        variant = ChipVariant.invited;
  const StatusChip.private({super.key})
      : label = 'private',
        variant = ChipVariant.private;
  const StatusChip.newBadge({super.key})
      : label = 'New',
        variant = ChipVariant.newBadge;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      ChipVariant.invited => (AppColors.border, AppColors.textMuted),
      // border fill, not bg: must stay visible on bg-colored secondary cards
      ChipVariant.private => (AppColors.border, AppColors.textMuted),
      ChipVariant.newBadge => (AppColors.accentSoft, AppColors.accentDeep),
      ChipVariant.warning => (const Color(0xFFF6E3CE), AppColors.warning),
      ChipVariant.danger => (const Color(0xFFF6D9D6), AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool onDark;

  const InitialsAvatar({super.key, required this.name, this.size = 40, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onDark ? AppColors.onAccent.withOpacity(0.18) : AppColors.accentSoft.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: onDark ? AppColors.onAccent : AppColors.accentDeep,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textMuted,
                )),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;

  const EmptyState({super.key, required this.icon, required this.message, this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textMuted.withOpacity(0.6)),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient placeholder for a video thumbnail, seeded by body part so the
/// library looks varied without real imagery.
class VideoThumb extends StatelessWidget {
  final String bodyPart;
  final double width;
  final double height;
  final bool playIcon;

  const VideoThumb({
    super.key,
    required this.bodyPart,
    this.width = 64,
    this.height = 44,
    this.playIcon = true,
  });

  // Tonal steps of the Tendo blue/petrol family only — thumbs must never
  // introduce a second accent hue (Colors.md rule 3). Teal steps come from
  // the clinic's own extended palette.
  static const _palettes = <List<Color>>[
    [Color(0xFF03607F), Color(0xFF0090C3)], // accentDeep → accent
    [Color(0xFF03262F), Color(0xFF0090C3)], // videoBg → accent
    [Color(0xFF0090C3), Color(0xFF6FC2DF)], // accent → soft sky
    [Color(0xFF26444D), Color(0xFF46707F)], // petrol slate
    [Color(0xFF2E5F5B), Color(0xFF58B0AA)], // clinic teal
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[bodyPart.hashCode.abs() % _palettes.length];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: playIcon
          ? Icon(Icons.play_arrow_rounded,
              color: AppColors.onAccent.withOpacity(0.85), size: height * 0.55)
          : null,
    );
  }
}

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
