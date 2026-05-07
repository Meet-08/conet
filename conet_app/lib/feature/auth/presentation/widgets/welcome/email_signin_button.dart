import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class EmailSignInButton extends StatelessWidget {
  const EmailSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return SizedBox(
      width: double.infinity,
      height: AppSpace.s48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: semantic.backgroundBrand,
          foregroundColor: semantic.textOnBrand,
          iconColor: semantic.iconOnBrand,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        ),
        onPressed: () => context.push('/email-signup'),
        icon: const Icon(FontAwesomeIcons.envelope, size: AppSpace.s16),
        label: Text(
          'Sign up with Email',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: semantic.textOnBrand),
        ),
      ),
    );
  }
}
