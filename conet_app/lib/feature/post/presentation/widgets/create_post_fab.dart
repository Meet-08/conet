import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostFab extends StatelessWidget {
  const CreatePostFab({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return FloatingActionButton(
      shape: const RoundedSuperellipseBorder(borderRadius: AppRadius.fullAll),
      backgroundColor: semantic.backgroundBrand,
      onPressed: () => context.push('/create-post'),
      child: Icon(
        CupertinoIcons.pencil_outline,
        size: 30,
        color: semantic.iconPrimary,
      ),
    );
  }
}
