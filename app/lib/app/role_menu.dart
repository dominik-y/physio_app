import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/locale_cubit.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Avatar menu shown in app bars: identity + "Switch role" (spec §15.1's
/// stand-in for the profile screen behind the avatar) + language switch.
class RoleMenuButton extends StatelessWidget {
  final String name;

  const RoleMenuButton({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isHr = context.watch<LocaleCubit>().state.languageCode == 'hr';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: l.profileTooltip,
        offset: const Offset(0, 46),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'switch', child: Text(l.switchRole)),
          PopupMenuItem(
            value: 'language',
            child: Text(isHr ? '🇬🇧 ${l.languageEnglish}' : '🇭🇷 ${l.languageCroatian}'),
          ),
        ],
        onSelected: (value) {
          if (value == 'switch') context.read<RoleCubit>().signOut();
          if (value == 'language') context.read<LocaleCubit>().toggle();
        },
        child: InitialsAvatar(name: name, size: 36),
      ),
    );
  }
}
