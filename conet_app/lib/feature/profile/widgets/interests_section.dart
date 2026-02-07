import 'package:flutter/material.dart';

class InterestsSection extends StatelessWidget {
  const InterestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final interests = [
      'Web Development',
      'Machine Learning',
      'UI/UX Design',
      'Data Science',
      'Photography',
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Interests',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text('See all', style: TextStyle(fontSize: 12)),
                SizedBox(width: 12),
                Text('Edit', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
