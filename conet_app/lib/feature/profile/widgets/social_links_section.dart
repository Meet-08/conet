import 'package:flutter/material.dart';

class SocialLinksSection extends StatelessWidget {
  const SocialLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              'Social Links',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.link), onPressed: () {}),
            IconButton(icon: const Icon(Icons.language), onPressed: () {}),
            IconButton(icon: const Icon(Icons.code), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
