import 'package:flutter/material.dart';
import 'package:conet_app/feature/login/widgets/login_header.dart';
import 'package:conet_app/feature/login/widgets/google_login_button.dart';
import 'package:conet_app/feature/login/widgets/divider_with_text.dart';
import 'package:conet_app/feature/login/widgets/email_field.dart';
import 'package:conet_app/feature/login/widgets/password_field.dart';
import 'package:conet_app/feature/login/widgets/forgot_password_text.dart';
import 'package:conet_app/feature/login/widgets/login_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
              LoginHeader(),
              SizedBox(height: 24),
              GoogleLoginButton(),
              SizedBox(height: 24),
              DividerWithText(text: 'Or continue with email'),
              SizedBox(height: 24),
              EmailField(),
              SizedBox(height: 16),
              PasswordField(),
              SizedBox(height: 10),
              ForgotPasswordText(),
              SizedBox(height: 24),
              LoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}
