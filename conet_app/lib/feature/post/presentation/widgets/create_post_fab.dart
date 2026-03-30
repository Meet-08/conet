import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostFab extends StatelessWidget {
  const CreatePostFab({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return FloatingActionButton(
      shape: RoundedSuperellipseBorder(borderRadius: .circular(60)),
      backgroundColor: semantic.backgroundBrand,
      onPressed: () => context.push('/create-post'),
      child: Icon(Icons.edit_outlined, size: 20, color: semantic.iconPrimary),
    );
  }
}
