import 'package:flutter/material.dart';

class CreatePostActionsRow extends StatelessWidget {
  final VoidCallback onMediaTap;

  const CreatePostActionsRow({super.key, required this.onMediaTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMediaTap,
          icon: const Icon(Icons.image_outlined),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.format_bold),
        const SizedBox(width: 16),
        const Icon(Icons.format_italic),
        const SizedBox(width: 16),
        const Icon(Icons.bar_chart),
      ],
    );
  }
}
