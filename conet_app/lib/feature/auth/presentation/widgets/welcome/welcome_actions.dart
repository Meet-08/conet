import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/google_auth_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/welcome/email_signin_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Column(
      children: [
        const GoogleAuthButton.primary(label: "Sign up with Google"),
        const SizedBox(height: AppSpace.s16),
        const EmailSignInButton(),
        const SizedBox(height: AppSpace.s20),
        Text.rich(
          TextSpan(
            text: "Already have an account? ",
            style: textTheme.bodySmall?.copyWith(color: semantic.textSecondary),
            children: [
              TextSpan(
                text: 'Log in',
                style: textTheme.bodyMedium?.copyWith(
                  color: NeutralPaletteLight.c500,
                  fontWeight: FontWeight.bold,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.s20),
          child: _TermsText(),
        ),
      ],
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Text(
      'By continuing, you agree to our Terms of Service and acknowledge our Privacy Policy.',
      textAlign: TextAlign.center,
      style: textTheme.labelSmall?.copyWith(color: semantic.textTertiary),
    );
  }
}
