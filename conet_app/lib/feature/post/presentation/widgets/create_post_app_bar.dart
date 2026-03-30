import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreatePostAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onPost;
  final bool isLoading;

  const CreatePostAppBar({
    super.key,
    required this.onPost,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Create Post',
        style: textTheme.titleMedium?.copyWith(color: semantic.textPrimary),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: semantic.backgroundDisabled,
              foregroundColor: semantic.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: isLoading ? null : onPost,
            child: isLoading
                ? const Loader(size: 20, strokeWidth: 2)
                : const Text('Post'),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
