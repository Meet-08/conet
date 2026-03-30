import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

class CreatePostPopularTags extends StatelessWidget {
  final ValueChanged<String> onTagSelected;

  const CreatePostPopularTags({super.key, required this.onTagSelected});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    final tags = [
      'programming',
      'webdev',
      'react',
      'javascript',
      'python',
      'ai',
      'machinelearning',
      'design',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular hashtags (Type to search for more):',
          style: textTheme.labelSmall?.copyWith(color: semantic.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => ActionChip(
                  label: Text('#$tag'),
                  backgroundColor: semantic.backgroundSecondary,
                  onPressed: () => onTagSelected(tag),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
