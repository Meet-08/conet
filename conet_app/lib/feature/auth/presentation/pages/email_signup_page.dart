import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/pages/otp_page.dart';
import 'package:conet_app/feature/auth/presentation/widgets/email_signup/email_signup_footer.dart';
import 'package:conet_app/feature/auth/presentation/widgets/email_signup/email_signup_form.dart';
import 'package:conet_app/feature/auth/presentation/widgets/email_signup/email_signup_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _termsAccepted = false;
  bool _otpPageOpened = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      AppToast.showWarning(context, 'Please accept the terms and conditions');
      return;
    }

    context.read<AuthBloc>().add(
      AuthSendOtp(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
      ),
    );
  }

  Future<void> _openOtpPage() async {
    _otpPageOpened = true;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpPage(email: _emailController.text.trim()),
      ),
    );

    if (mounted) {
      setState(() {
        _otpPageOpened = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        } else if (state is AuthOtpSentSuccess) {
          setState(() => _isLoading = false);
          if (!_otpPageOpened) {
            _openOtpPage();
          }
        } else if (state is AuthFailure) {
          setState(() => _isLoading = false);
          AppToast.showError(context, state.message);
        } else {
          setState(() => _isLoading = false);
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
                  const EmailSignupHeader(),
                  const SizedBox(height: 28),
                  EmailSignupForm(
                    emailController: _emailController,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    termsAccepted: _termsAccepted,
                    onTermsChanged: (value) =>
                        setState(() => _termsAccepted = value ?? false),
                    onSubmit: _onSubmit,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  const EmailSignupFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
