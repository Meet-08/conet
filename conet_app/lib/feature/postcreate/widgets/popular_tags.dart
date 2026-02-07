import 'package:flutter/material.dart';

class PopularTags extends StatelessWidget {
  const PopularTags({super.key});

  @override
  Widget build(BuildContext context) {
    final tags = [
      '#programming',
      '#webdev',
      '#react',
      '#javascript',
      '#python',
      '#ai',
      '#machinelearning',
      '#design',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular hashtags (Type to search for more):',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.grey.shade100,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
