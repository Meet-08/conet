import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreatePostActionsRow extends StatelessWidget {
  final VoidCallback onMediaTap;

  const CreatePostActionsRow({super.key, required this.onMediaTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMediaTap,
          icon: const FaIcon(FontAwesomeIcons.paperclip),
        ),
        const SizedBox(width: 16),
        const FaIcon(FontAwesomeIcons.bold),
        const SizedBox(width: 16),
        const FaIcon(FontAwesomeIcons.italic),
        const SizedBox(width: 16),
        const FaIcon(FontAwesomeIcons.chartBar),
      ],
    );
  }
}
