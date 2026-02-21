import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A reusable password input field for authentication forms.
///
/// Includes visibility toggle and validation support.
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

  /// Creates a password field for login.
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

  /// Creates a password field for signup/registration.
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
      label: 'Password *',
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
      label: 'Confirm Password *',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isRequired ? '${widget.label} *' : widget.label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
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
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FaIcon(
                FontAwesomeIcons.lock,
                size: 20,
                color: Colors.grey.shade700,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: FaIcon(
                  _obscureText
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                onPressed: _toggleVisibility,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
