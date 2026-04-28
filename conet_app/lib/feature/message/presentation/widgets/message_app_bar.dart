import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MessageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchPressed;
  final VoidCallback? onAddPressed;
  final bool isSearching;

  const MessageAppBar({
    super.key,
    this.onSearchPressed,
    this.onAddPressed,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Messages',
        style: AppTextStyles.headingH3.copyWith(
          fontWeight: AppTypographyTokens.weightSemibold,
        ),
      ),
      actions: [
        IconButton(
          icon: FaIcon(
            isSearching
                ? FontAwesomeIcons.xmark
                : FontAwesomeIcons.magnifyingGlass,
          ),
          onPressed: onSearchPressed,
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.plus),
          onPressed: onAddPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
