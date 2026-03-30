import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        ),
        onPressed: () => context.push('/email-signup'),
        icon: const Icon(FontAwesomeIcons.envelope, size: 18),
        label: Text(
          'Sign up with Email',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
