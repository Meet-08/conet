import 'package:conet_app/feature/googlesign/widgets/add_details_form.dart';
import 'package:conet_app/feature/googlesign/widgets/add_details_header.dart';
import 'package:flutter/material.dart';

class AddDetailsPage extends StatelessWidget {
  final bool isGoogle;

  const AddDetailsPage({super.key, required this.isGoogle});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              AddDetailsHeader(),
              SizedBox(height: 32),
              AddDetailsForm(),
            ],
          ),
        ),
      ),
    );
  }
}
