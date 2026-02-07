import 'package:flutter/material.dart';

class WelcomeTitle extends StatelessWidget {
  const WelcomeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Join your college student community',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 15, color: Colors.grey),
    );
  }
}
