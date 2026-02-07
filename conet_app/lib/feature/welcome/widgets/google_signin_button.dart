import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () => context.push('/googlesign'),
        child: const Text(
          'Sign up with Google',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
