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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.black : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const Loader(size: 20, strokeWidth: 2, color: Colors.white)
            : Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
