import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailSignupFooter extends StatelessWidget {
  const EmailSignupFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: const TextStyle(fontSize: 14),
          children: [
            TextSpan(
              text: 'Log in',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
