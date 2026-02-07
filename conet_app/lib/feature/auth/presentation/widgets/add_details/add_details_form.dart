import 'package:conet_app/feature/auth/presentation/widgets/add_details/details_first_name_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/add_details/details_last_name_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/add_details/finish_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/add_details/username_field.dart';
import 'package:flutter/material.dart';

class AddDetailsForm extends StatelessWidget {
  const AddDetailsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DetailsFirstNameField(),
        SizedBox(height: 16),
        DetailsLastNameField(),
        SizedBox(height: 16),
        UsernameField(),
        SizedBox(height: 32),
        FinishButton(),
      ],
    );
  }
}
