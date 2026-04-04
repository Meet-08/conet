import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CreatePostTextField extends StatelessWidget {
  final QuillController controller;

  const CreatePostTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      decoration: BoxDecoration(
        color: semantic.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: semantic.borderDefault),
      ),
      padding: const EdgeInsets.all(16),
      child: QuillEditor.basic(
        controller: controller,
        config: const QuillEditorConfig(
          minHeight: 110,
          placeholder: "What's on your mind?",
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
