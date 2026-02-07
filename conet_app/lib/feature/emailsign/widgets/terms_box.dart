import 'package:flutter/material.dart';

class TermsBox extends StatelessWidget {
  const TermsBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'By signing up, you agree to our Terms of Service and Privacy Policy. '
        'Your information is collected and processed according to our data policies.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
