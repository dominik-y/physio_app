import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/language_toggle.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

class RoleGatePage extends StatelessWidget {
  const RoleGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.md,
              child: LanguageToggle(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: 'Poliklinika Tendo',
                        image: true,
                        child: Image.asset(
                          'assets/branding/tendo_logo_light.png',
                          width: 250,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l.roleGateSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.xl),
                      _RoleCard(
                        icon: Icons.medical_services_outlined,
                        title: l.enterAsPhysio,
                        subtitle: DemoData.physioName,
                        onTap: () =>
                            context.read<RoleCubit>().enterAs(UserRole.physio),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Both role cards identical — the patient card used to
                      // carry a brand wash; owner call 2026-08-25: unhighlight.
                      _RoleCard(
                        icon: Icons.accessibility_new_rounded,
                        title: l.enterAsPatient,
                        subtitle: DemoData.currentPatientName,
                        onTap: () =>
                            context.read<RoleCubit>().enterAs(UserRole.patient),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l.roleGateFooter,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentSoft.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              child: Icon(icon, color: AppColors.accentDeep),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Uđi kao fizioterapeut" clips at 320px on one line — the
                  // first tap of the demo must never ellipsize (wrap instead).
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
