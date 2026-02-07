import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:conet_app/feature/welcome/widgets/email_signin_button.dart';
import 'package:conet_app/feature/welcome/widgets/google_signin_button.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GoogleSignInButton(),
        const SizedBox(height: 14),
        const EmailSignInButton(),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Already have an account? ',
            children: [
              TextSpan(
                text: 'Log in',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.go('/login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'By continuing, you agree to our Terms of Service and acknowledge our Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
