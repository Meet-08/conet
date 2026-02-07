import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: false,
      actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
