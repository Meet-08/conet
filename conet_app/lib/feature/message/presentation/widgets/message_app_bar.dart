import 'package:flutter/material.dart';

class MessageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchPressed;
  final VoidCallback? onAddPressed;

  const MessageAppBar({super.key, this.onSearchPressed, this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Messages',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: onSearchPressed),
        IconButton(icon: const Icon(Icons.add), onPressed: onAddPressed),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
