import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailSignInButton extends StatelessWidget {
  const EmailSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () => context.push('/email-signup'),
        icon: const Icon(Icons.email_outlined, size: 20),
        label: const Text(
          'Sign up with Email',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
