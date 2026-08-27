import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/locale_cubit.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/firebase/auth_failure_l10n.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Avatar menu shown in app bars: identity + "Switch role" (spec §15.1's
/// stand-in for the profile screen behind the avatar) + language switch.
/// Under a real session (Firebase flavor) "switch role" becomes sign-out,
/// and patient sessions gain account deletion (App Store 5.1.1(v)).
class RoleMenuButton extends StatelessWidget {
  final String name;

  const RoleMenuButton({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isHr = context.watch<LocaleCubit>().state.languageCode == 'hr';
    final session = SessionScope.maybeOf(context);
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
          PopupMenuItem(
              value: 'switch',
              child: Text(session == null ? l.switchRole : l.signOutLabel)),
          PopupMenuItem(
            value: 'language',
            child: Text(isHr
                ? '🇬🇧 ${l.languageEnglish}'
                : '🇭🇷 ${l.languageCroatian}'),
          ),
          if (session?.deleteAccount != null)
            PopupMenuItem(
              value: 'delete',
              child: Text(l.deleteAccountLabel,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
        onSelected: (value) {
          if (value == 'switch') {
            if (session == null) {
              context.read<RoleCubit>().signOut();
            } else {
              session.signOut();
            }
          }
          if (value == 'language') context.read<LocaleCubit>().toggle();
          if (value == 'delete') _confirmDelete(context, session!);
        },
        child: InitialsAvatar(name: name, size: 36),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, AppSession session) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  var busy = false;
  String? error;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(l.deleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.deleteAccountBody),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l.passwordLabel,
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final failure =
                        await session.deleteAccount!(controller.text);
                    if (!dialogContext.mounted) return;
                    if (failure == null) {
                      // Auth stream flips to signed-out; the bootstrap
                      // swaps the whole app out from under this dialog.
                      Navigator.of(dialogContext).pop();
                    } else {
                      setState(() {
                        busy = false;
                        error = failure.message(l);
                      });
                    }
                  },
            child: Text(l.deleteAccountConfirm),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}
