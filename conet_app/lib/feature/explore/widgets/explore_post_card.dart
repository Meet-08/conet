import 'package:flutter/material.dart';

class ExplorePostCard extends StatelessWidget {
  const ExplorePostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const CircleAvatar(
                    child: Text('DP'),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'David Park',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Text(
                    '6h',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Content
              const Text(
                'Attending my first AI/ML conference today! '
                'The keynote on transformer models was mind-blowing.\n\n'
                'Here are my top 3 takeaways:\n'
                '1. Attention is all you need (literally)\n'
                '2. Fine-tuning > training from scratch\n'
                '3. Ethical AI considerations are more important than ever',
              ),

              const SizedBox(height: 8),

              // Tags
              Wrap(
                spacing: 8,
                children: const [
                  _Tag('#MachineLearning'),
                  _Tag('#AI'),
                  _Tag('#Conference'),
                  _Tag('#Learning'),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: const [
                  _Action(icon: Icons.favorite_border, count: '567'),
                  SizedBox(width: 16),
                  _Action(icon: Icons.chat_bubble_outline, count: '89'),
                  SizedBox(width: 16),
                  Icon(Icons.share_outlined),
                  Spacer(),
                  Icon(Icons.bookmark_border),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String count;

  const _Action({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 4),
        Text(count),
      ],
    );
  }
}
