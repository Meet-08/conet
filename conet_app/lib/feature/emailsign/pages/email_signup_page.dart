import 'package:conet_app/feature/emailsign/widgets/email_signup_footer.dart';
import 'package:conet_app/feature/emailsign/widgets/email_signup_form.dart';
import 'package:conet_app/feature/emailsign/widgets/email_signup_header.dart';
import 'package:flutter/material.dart';

class EmailSignupPage extends StatelessWidget {
  const EmailSignupPage({super.key});

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
              EmailSignupHeader(),
              SizedBox(height: 28),
              EmailSignupForm(),
              SizedBox(height: 24),
              EmailSignupFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
