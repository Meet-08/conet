import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class EmailSignInButton extends StatelessWidget {
  const EmailSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () => context.push('/emailsign'),
        child: const Text('Sign in with Email'),
      ),
    );
  }
}
