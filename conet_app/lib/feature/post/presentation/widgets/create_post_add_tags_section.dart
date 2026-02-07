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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Tags', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add hashtag...',
                  prefixIcon: const Icon(Icons.tag),
                  filled: true,
                  fillColor: Colors.grey.shade100,
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
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white),
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
                    backgroundColor: Colors.blue.shade50,
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
