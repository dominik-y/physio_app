import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';

class RoleGatePage extends StatelessWidget {
  const RoleGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                  const Text('Showcase build — pick a side to explore',
                      textAlign: TextAlign.center, style: AppTypography.bodySmall),
                  const SizedBox(height: AppSpacing.xl),
                  _RoleCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Enter as physio',
                    subtitle: DemoData.physioName,
                    onTap: () => context.read<RoleCubit>().enterAs(UserRole.physio),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RoleCard(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Enter as patient',
                    subtitle: DemoData.currentPatientName,
                    accented: true,
                    onTap: () => context.read<RoleCubit>().enterAs(UserRole.patient),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Demo data · resets on restart',
                      textAlign: TextAlign.center, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool accented;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accented = false,
  });

  @override
  Widget build(BuildContext context) {
    // The patient card carries a soft brand wash so the two roles read as
    // different at a glance, not only by their labels.
    return AppCard(
      onTap: onTap,
      color: accented ? const Color(0xFFEAF5FA) : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accented
                  ? AppColors.accent.withOpacity(0.14)
                  : AppColors.accentSoft.withOpacity(0.4),
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            child: Icon(icon, color: AppColors.accentDeep),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
