import 'package:conet_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String hintText;
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
      label: isRequired ? 'Email' : 'Email (optional)',
      hintText: 'your.email@example.com',
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
      label: isRequired ? 'First Name' : 'First Name (optional)',
      hintText: 'Enter your first name',
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
      label: isRequired ? 'Last Name' : 'Last Name (optional)',
      hintText: 'Enter your last name',
      controller: controller,
      isRequired: isRequired,
      validator:
          validator ??
          (isRequired ? _defaultLastNameValidator : _optionalLastNameValidator),
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
      label: isRequired ? 'Username' : 'Username (optional)',
      hintText: 'johndoe4171',
      suffixIcon: onRefresh != null
          ? IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.arrowsRotate,
                size: AppTypographyTokens.size16,
              ),
              onPressed: onRefresh,
            )
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
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'Last name can only contain letters';
    }
    return null;
  }

  static String? _optionalLastNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return _defaultLastNameValidator(value);
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
    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpace.s8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: textInputAction,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            hintStyle: AppTextStyles.bodyDefault.copyWith(
              color: semantic.textSecondary,
            ),
            labelStyle: AppTextStyles.bodyDefault,
            filled: true,
            fillColor: semantic.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s12,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(
                color: context.semanticColors.borderDefault,
                style: BorderStyle.solid,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(
                color: context.semanticColors.borderDefault,
                style: BorderStyle.solid,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(
                color: semantic.borderFocus,
                style: BorderStyle.solid,
              ),
            ),
            errorStyle: AppTextStyles.micro.copyWith(color: semantic.textError),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppSpace.s8),
          Text(
            helperText!,
            style: AppTextStyles.micro.copyWith(color: semantic.textTertiary),
          ),
        ],
      ],
    );
  }
}
