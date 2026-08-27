import 'package:flutter/material.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

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
    // MacJack cards are borderless: one soft ink shadow does all the lifting
    // against the near-white bg.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: color ?? AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
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
    // accentDeep, not accent — white label on accent is 3.6:1 (fails AA);
    // Colors.md rule 4 reserves brand blue for fills without text.
    this.background = AppColors.accentDeep,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: const StadiumBorder(),
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
    // MacJack secondary: a flat tonal pill (light brand tint, no border).
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentTint,
        foregroundColor: AppColors.accentDeep,
        disabledBackgroundColor: AppColors.accentTint.withOpacity(0.5),
        disabledForegroundColor: AppColors.accentDeep.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        shape: const StadiumBorder(),
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
        borderRadius: BorderRadius.circular(AppRadii.tile),
        side: BorderSide(
          color: overridden ? AppColors.accent : AppColors.border,
          width: overridden ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.tile),
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
              // Croatian labels run long (PONAVLJANJA) — scale, never clip.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.textMuted,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChipVariant { invited, private, newBadge, warning, danger }

class StatusChip extends StatelessWidget {
  /// Explicit label; the named constructors leave it null and localize
  /// their standard label at build time instead.
  final String? label;
  final ChipVariant variant;

  const StatusChip({super.key, required String this.label, required this.variant});

  const StatusChip.invited({super.key})
      : label = null,
        variant = ChipVariant.invited;
  const StatusChip.private({super.key})
      : label = null,
        variant = ChipVariant.private;
  const StatusChip.newBadge({super.key})
      : label = null,
        variant = ChipVariant.newBadge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = label ??
        switch (variant) {
          ChipVariant.invited => l.invitedChip,
          ChipVariant.private => l.privateChip,
          ChipVariant.newBadge => l.newChip,
          _ => '',
        };
    final (bg, fg) = switch (variant) {
      ChipVariant.invited => (AppColors.border, AppColors.chipText),
      // border fill, not bg: must stay visible on bg-colored secondary cards
      ChipVariant.private => (AppColors.border, AppColors.chipText),
      ChipVariant.newBadge => (AppColors.accentSoft, AppColors.accentDeep),
      ChipVariant.warning => (AppColors.warningSoft, AppColors.warningChipText),
      ChipVariant.danger => (AppColors.dangerSoft, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(text,
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
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: playIcon
          ? Icon(Icons.play_arrow_rounded,
              color: AppColors.onAccent.withOpacity(0.85), size: height * 0.55)
          : null,
    );
  }
}

/// Centers screen content in a max-width column so list screens read as a
/// column, not an edge-to-edge stretch, on desktop/tablet (MacBook demo).
class ContentColumn extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentColumn({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
