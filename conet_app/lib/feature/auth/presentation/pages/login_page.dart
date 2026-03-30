import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_password_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_submit_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/google_auth_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/login/divider_with_text.dart';
import 'package:conet_app/feature/auth/presentation/widgets/login/forgot_password_text.dart';
import 'package:conet_app/feature/auth/presentation/widgets/login/login_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final semantic = context.semanticColors;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        } else if (state is AuthSuccess) {
          setState(() => _isLoading = false);
        } else if (state is AuthFailure) {
          setState(() => _isLoading = false);
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: AppSpace.s16,
          title: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.fullAll,
                    ),
                  ),
                  onPressed: () => context.pop(),
                  child: FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    size: AppTypographyTokens.size16,
                    color: semantic.iconPrimary,
                  ),
                ),
              ),
              const Text('Back', style: AppTextStyles.button),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoginHeader(),
                  const SizedBox(height: 28),
                  const GoogleAuthButton.secondary(),
                  const SizedBox(height: 24),
                  const DividerWithText(text: 'Or continue with email'),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Email or Username',
                    hintText: 'Email or username',
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email or username is required';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField.login(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onLogin(),
                  ),
                  const SizedBox(height: 8),
                  const ForgotPasswordText(),
                  const SizedBox(height: 34),
                  AuthSubmitButton.login(
                    isLoading: _isLoading,
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
