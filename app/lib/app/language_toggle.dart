import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/locale_cubit.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Compact flag pill that switches the app language (🇭🇷 default ↔ 🇬🇧).
/// Lives top-right on the role gate; the role menu offers the same switch.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isHr = locale.languageCode == 'hr';
        return Semantics(
          button: true,
          label: l.languageToggleLabel,
          child: Material(
            color: AppColors.surface,
            shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => context.read<LocaleCubit>().toggle(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isHr ? '🇭🇷' : '🇬🇧',
                        style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      isHr ? 'HR' : 'EN',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
