import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreatePostActionsRow extends StatelessWidget {
  final VoidCallback onMediaTap;
  final VoidCallback onBoldTap;
  final VoidCallback onItalicTap;
  final VoidCallback onListTap;
  final bool isBoldActive;
  final bool isItalicActive;
  final bool isListActive;

  const CreatePostActionsRow({
    super.key,
    required this.onMediaTap,
    required this.onBoldTap,
    required this.onItalicTap,
    required this.onListTap,
    required this.isBoldActive,
    required this.isItalicActive,
    required this.isListActive,
  });

  Widget _actionIcon({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? colors.primaryContainer : Colors.transparent,
        ),
        child: FaIcon(
          icon,
          color: isActive ? colors.onPrimaryContainer : colors.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMediaTap,
          icon: const FaIcon(FontAwesomeIcons.paperclip),
        ),
        const SizedBox(width: 16),
        _actionIcon(
          context: context,
          icon: FontAwesomeIcons.bold,
          onTap: onBoldTap,
          isActive: isBoldActive,
        ),
        const SizedBox(width: 16),
        _actionIcon(
          context: context,
          icon: FontAwesomeIcons.italic,
          onTap: onItalicTap,
          isActive: isItalicActive,
        ),
        const SizedBox(width: 16),
        _actionIcon(
          context: context,
          icon: FontAwesomeIcons.chartBar,
          onTap: onListTap,
          isActive: isListActive,
        ),
      ],
    );
  }
}
