import 'package:conet_app/core/common/utils/app_toast.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_password_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_submit_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/google_auth_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/login/divider_with_text.dart';
import 'package:conet_app/feature/auth/presentation/widgets/login/forgot_password_text.dart';
import 'package:conet_app/feature/auth/presentation/widgets/login/login_header.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        } else if (state is AuthSuccess) {
          setState(() => _isLoading = false);
          // Navigation is handled by AppRouter based on user state
        } else if (state is AuthFailure) {
          setState(() => _isLoading = false);
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const LoginHeader(),
                  const SizedBox(height: 24),
                  const GoogleAuthButton(),
                  const SizedBox(height: 24),
                  const DividerWithText(text: 'Or continue with email'),
                  const SizedBox(height: 24),
                  AuthTextField.email(
                    controller: _emailController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField.login(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onLogin(),
                  ),
                  const SizedBox(height: 10),
                  const ForgotPasswordText(),
                  const SizedBox(height: 24),
                  AuthSubmitButton.login(
                    isLoading: _isLoading,
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: const TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.go('/email-signup'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
