import 'package:flutter/material.dart';

class WelcomeLogo extends StatelessWidget {
  const WelcomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/app_icon.png',
            height: 56,
            width: 56,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Conet',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
