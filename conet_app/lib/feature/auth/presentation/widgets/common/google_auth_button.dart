import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum GoogleAuthButtonVariant { primary, secondary }

class GoogleAuthButton extends StatelessWidget {
  final String? label;
  final GoogleAuthButtonVariant variant;

  const GoogleAuthButton({
    super.key,
    this.label,
    this.variant = GoogleAuthButtonVariant.secondary,
  });

  const GoogleAuthButton.primary({super.key, this.label})
    : variant = GoogleAuthButtonVariant.primary;

  const GoogleAuthButton.secondary({super.key, this.label})
    : variant = GoogleAuthButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isPrimary = variant == GoogleAuthButtonVariant.primary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: isPrimary ? AppRadius.fullAll : AppRadius.mdAll,
          ),
          backgroundColor: isPrimary
              ? semantic.backgroundBrand
              : semantic.surfaceBase,
          foregroundColor: isPrimary
              ? semantic.textOnBrand
              : semantic.textPrimary,
          side: isPrimary ? null : BorderSide(color: semantic.borderDefault),
        ),
        onPressed: () {
          context.read<AuthBloc>().add(AuthSigninWithGoogle());
        },
        icon: const Icon(FontAwesomeIcons.google),
        label: Text(
          label ?? 'Continue with Google',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
