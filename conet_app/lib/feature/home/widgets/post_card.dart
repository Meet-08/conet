import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: const Text('PS'),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priya Sharma',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '36m',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
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
                'Just finished our Machine Learning project! 🚀\n'
                'Working with neural networks has been an incredible learning experience. '
                'Our team built a sentiment analysis tool for social media posts.',
              ),

              const SizedBox(height: 8),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    'https://picsum.photos/600/400',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tags
              const Wrap(
                spacing: 8,
                children: [
                  _TagChip(text: '#MachineLearning'),
                  _TagChip(text: '#AI'),
                  _TagChip(text: '#Project'),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
              const Row(
                children: [
                  _ActionItem(icon: Icons.favorite_border, label: '24'),
                  SizedBox(width: 16),
                  _ActionItem(icon: Icons.chat_bubble_outline, label: '8'),
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

class _TagChip extends StatelessWidget {
  final String text;

  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 4), Text(label)],
    );
  }
}
