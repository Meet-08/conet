import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthPasswordField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AuthPasswordField({
    super.key,
    this.label = 'Password',
    this.hintText = 'Enter your password',
    this.controller,
    this.isRequired = true,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
  });

  factory AuthPasswordField.login({
    Key? key,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthPasswordField(
      key: key,
      label: 'Password',
      hintText: 'Enter your password',
      controller: controller,
      validator: validator ?? _defaultPasswordValidator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  factory AuthPasswordField.signup({
    Key? key,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthPasswordField(
      key: key,
      label: 'Password',
      hintText: 'Create a strong password',
      controller: controller,
      validator: validator ?? _strongPasswordValidator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  /// Creates a confirm password field.
  factory AuthPasswordField.confirm({
    Key? key,
    TextEditingController? controller,
    TextEditingController? passwordController,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthPasswordField(
      key: key,
      label: 'Confirm Password',
      hintText: 'Re-enter your password',
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (passwordController != null && value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  static String? _defaultPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? _strongPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isRequired ? widget.label : "${widget.label} (optional)",
          style: textTheme.titleMedium?.copyWith(
            color: semantic.textPrimary,
            fontWeight: AppTypographyTokens.weightMedium,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: FaIcon(
                  _obscureText
                      ? FontAwesomeIcons.eye
                      : FontAwesomeIcons.eyeSlash,
                  size: AppTypographyTokens.size16,
                  color: semantic.iconSecondary,
                ),
                onPressed: _toggleVisibility,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: semantic.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s12,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(color: semantic.borderFocus, width: 1.2),
            ),
            errorStyle: textTheme.labelSmall?.copyWith(
              color: semantic.textError,
            ),
          ),
        ),
      ],
    );
  }
}
