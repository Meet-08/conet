import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

class CreatePostAddTagsSection extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final TextEditingController controller;

  const CreatePostAddTagsSection({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Tags',
          style: textTheme.titleSmall?.copyWith(color: semantic.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add hashtag...',
                  prefixIcon: Icon(Icons.tag, color: semantic.iconSecondary),
                  filled: true,
                  fillColor: semantic.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onAddTag(value.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (controller.text.trim().isNotEmpty) {
                  onAddTag(controller.text.trim());
                  controller.clear();
                }
              },
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: semantic.backgroundInverse,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add, color: semantic.iconInverse),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    backgroundColor: semantic.backgroundSelected,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => onRemoveTag(tag),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
