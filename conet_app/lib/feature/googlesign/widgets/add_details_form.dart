import 'package:flutter/material.dart';
import 'package:conet_app/feature/googlesign/widgets/first_name_field.dart';
import 'package:conet_app/feature/googlesign/widgets/last_name_field.dart';
import 'package:conet_app/feature/googlesign/widgets/username_field.dart';
import 'package:conet_app/feature/googlesign/widgets/finish_button.dart';

class AddDetailsForm extends StatelessWidget {
  const AddDetailsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FirstNameField(),
        SizedBox(height: 16),
        LastNameField(),
        SizedBox(height: 16),
        UsernameField(),
        SizedBox(height: 32),
        FinishButton(),
      ],
    );
  }
}
