import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

class CreatePostTextField extends StatelessWidget {
  final TextEditingController controller;

  const CreatePostTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 5,
      decoration: InputDecoration(
        hintText: "What's on your mind?",
        filled: true,
        fillColor: semantic.backgroundSecondary,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: semantic.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: semantic.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: semantic.borderFocus, width: 1.5),
        ),
      ),
    );
  }
}
