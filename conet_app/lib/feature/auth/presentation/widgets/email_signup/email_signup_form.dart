import 'package:conet_app/feature/auth/presentation/widgets/common/auth_submit_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/email_signup/terms_box.dart';
import 'package:flutter/material.dart';

class EmailSignupForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const EmailSignupForm({
    super.key,
    required this.emailController,
    required this.firstNameController,
    required this.lastNameController,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthTextField.email(
          controller: emailController,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AuthTextField.firstName(
          controller: firstNameController,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AuthTextField.lastName(
          controller: lastNameController,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        TermsBox(value: termsAccepted, onChanged: onTermsChanged),
        const SizedBox(height: 24),
        AuthSubmitButton.continue_(isLoading: isLoading, onPressed: onSubmit),
      ],
    );
  }
}
