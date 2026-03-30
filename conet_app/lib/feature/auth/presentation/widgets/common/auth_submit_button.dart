import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:flutter/material.dart';

/// A reusable submit button for authentication forms.
class AuthSubmitButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;

  const AuthSubmitButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
  });

  /// Creates a login button.
  factory AuthSubmitButton.login({
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AuthSubmitButton(
      key: key,
      text: 'Log in',
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  /// Creates a continue/signup button.
  factory AuthSubmitButton.continue_({
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AuthSubmitButton(
      key: key,
      text: 'Continue',
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  /// Creates a finish button.
  factory AuthSubmitButton.finish({
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AuthSubmitButton(
      key: key,
      text: 'Finish',
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          backgroundColor: isPrimary
              ? semantic.backgroundBrand
              : semantic.backgroundDisabled,
          foregroundColor: isPrimary
              ? semantic.textOnBrand
              : semantic.textDisabled,
          disabledBackgroundColor: semantic.backgroundDisabled,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? Loader(size: 20, strokeWidth: 2, color: semantic.iconOnBrand)
            : Text(text, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}
