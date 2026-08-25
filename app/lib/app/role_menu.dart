import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/role_cubit.dart';
import 'package:physio_app/design_system/components.dart';

/// Avatar menu shown in app bars: identity + "Switch role" (spec §15.1's
/// stand-in for the profile screen behind the avatar).
class RoleMenuButton extends StatelessWidget {
  final String name;

  const RoleMenuButton({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: 'Profile',
        offset: const Offset(0, 46),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'switch', child: Text('Switch role')),
        ],
        onSelected: (value) {
          if (value == 'switch') context.read<RoleCubit>().signOut();
        },
        child: InitialsAvatar(name: name, size: 36),
      ),
    );
  }
}
