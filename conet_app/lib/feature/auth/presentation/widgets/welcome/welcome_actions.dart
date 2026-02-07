import 'package:conet_app/feature/auth/presentation/widgets/common/google_auth_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/welcome/email_signin_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GoogleAuthButton(),
        const SizedBox(height: 14),
        const EmailSignInButton(),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            text: "Don't have an account? ",
            style: const TextStyle(fontSize: 14),
            children: [
              TextSpan(
                text: 'Sign up',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/email-signup'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'By continuing, you agree to our Terms of Service and acknowledge our Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
