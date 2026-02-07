import 'package:conet_app/feature/emailsign/widgets/continue_button.dart';
import 'package:conet_app/feature/emailsign/widgets/email_field.dart';
import 'package:conet_app/feature/emailsign/widgets/first_name_field.dart';
import 'package:conet_app/feature/emailsign/widgets/last_name_field.dart';
import 'package:conet_app/feature/emailsign/widgets/terms_box.dart';
import 'package:flutter/material.dart';

class EmailSignupForm extends StatelessWidget {
  const EmailSignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        EmailField(),
        SizedBox(height: 16),
        FirstNameField(),
        SizedBox(height: 16),
        LastNameField(),
        SizedBox(height: 16),
        TermsBox(),
        SizedBox(height: 24),
        ContinueButton(),
      ],
    );
  }
}
