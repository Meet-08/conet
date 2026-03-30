import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleAuthButton extends StatelessWidget {
  final String? label;
  const GoogleAuthButton({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
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
