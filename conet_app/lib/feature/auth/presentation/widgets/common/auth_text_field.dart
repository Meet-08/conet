import 'package:flutter/material.dart';

/// A reusable text input field for authentication forms.
///
/// Supports email, text, and other input types with consistent styling.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isRequired;
  final String? helperText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.helperText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
  });

  /// Creates an email input field with pre-configured settings.
  factory AuthTextField.email({
    Key? key,
    TextEditingController? controller,
    bool isRequired = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthTextField(
      key: key,
      label: isRequired ? 'Email *' : 'Email',
      hintText: 'your.email@example.com',
      prefixIcon: Icons.email_outlined,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      isRequired: isRequired,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  /// Creates a first name input field.
  factory AuthTextField.firstName({
    Key? key,
    TextEditingController? controller,
    bool isRequired = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthTextField(
      key: key,
      label: isRequired ? 'First Name *' : 'First Name',
      hintText: 'Enter your first name',
      prefixIcon: Icons.person_outline,
      controller: controller,
      isRequired: isRequired,
      validator: validator ?? (isRequired ? _defaultFirstNameValidator : null),
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  /// Creates a last name input field.
  factory AuthTextField.lastName({
    Key? key,
    TextEditingController? controller,
    bool isRequired = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthTextField(
      key: key,
      label: isRequired ? 'Last Name *' : 'Last Name',
      hintText: 'Enter your last name (optional)',
      prefixIcon: Icons.person_outline,
      controller: controller,
      isRequired: isRequired,
      validator: validator ?? (isRequired ? _defaultLastNameValidator : null),
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  /// Creates a username input field with refresh button.
  factory AuthTextField.username({
    Key? key,
    TextEditingController? controller,
    bool isRequired = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    VoidCallback? onRefresh,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return AuthTextField(
      key: key,
      label: isRequired ? 'Username *' : 'Username',
      hintText: 'johndoe4171',
      prefixIcon: Icons.alternate_email,
      suffixIcon: onRefresh != null
          ? IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh)
          : null,
      controller: controller,
      isRequired: isRequired,
      helperText: 'Your username is unique and cannot be changed later',
      validator: validator ?? _defaultUsernameValidator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  static String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? _defaultFirstNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'First name can only contain letters';
    }
    return null;
  }

  static String? _defaultLastNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'Last name can only contain letters';
    }
    return null;
  }

  static String? _defaultUsernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Username must be 20 characters or less';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
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
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
