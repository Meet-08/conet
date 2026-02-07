import 'package:flutter/material.dart';

class AddDetailsHeader extends StatelessWidget {
  const AddDetailsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 6),
              Text('Back'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Complete Your Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          "Let's set up your profile to get started",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
