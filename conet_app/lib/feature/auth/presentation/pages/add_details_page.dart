import 'dart:math';

import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/add_details/add_details_header.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_password_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_submit_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AddDetailsPage extends StatefulWidget {
  /// If true, user signed in with Google (show firstName, lastName, username)
  /// If false, user signed in with Email (show password, confirmPassword, username)
  final bool isGoogle;

  const AddDetailsPage({super.key, this.isGoogle = true});

  @override
  State<AddDetailsPage> createState() => _AddDetailsPageState();
}

class _AddDetailsPageState extends State<AddDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Google sign-in fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Email sign-in fields
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Common field
  final _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isGeneratingUsername = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Generates a unique username and validates with Supabase
  Future<void> _generateUniqueUsername() async {
    final firstName = _firstNameController.text.toLowerCase().trim();
    final lastName = _lastNameController.text.toLowerCase().trim();

    if (firstName.isEmpty) return;

    setState(() => _isGeneratingUsername = true);

    try {
      String username;
      bool isAvailable = false;
      int attempts = 0;
      const maxAttempts = 5;

      final supabase = serviceLocator<SupabaseClient>();

      while (!isAvailable && attempts < maxAttempts) {
        final random = Random().nextInt(9999);
        username = '$firstName${lastName.isEmpty ? '' : lastName[0]}$random';

        // Check availability in Supabase
        final result = await supabase
            .from('users')
            .select('username')
            .eq('username', username)
            .maybeSingle();

        isAvailable = result == null;
        attempts++;

        if (isAvailable) {
          _usernameController.text = username;
          break;
        }
      }

      // If all attempts failed, use timestamp for uniqueness
      if (!isAvailable) {
        final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
        _usernameController.text =
            '$firstName${lastName.isEmpty ? '' : lastName[0]}$timestamp';
      }
    } catch (e) {
      // Fallback to simple generation on error
      final random = DateTime.now().millisecondsSinceEpoch % 10000;
      _usernameController.text =
          '$firstName${lastName.isEmpty ? '' : lastName[0]}$random';
    } finally {
      if (mounted) {
        setState(() => _isGeneratingUsername = false);
      }
    }
  }

  /// Generates a random secure password for Google sign-in users
  String _generateSecurePassword() {
    const length = 16;
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    const allChars = lowercase + uppercase + numbers + special;

    final random = Random.secure();

    // Ensure at least one of each type
    final password = StringBuffer();
    password.write(lowercase[random.nextInt(lowercase.length)]);
    password.write(uppercase[random.nextInt(uppercase.length)]);
    password.write(numbers[random.nextInt(numbers.length)]);
    password.write(special[random.nextInt(special.length)]);

    // Fill the rest randomly
    for (var i = 4; i < length; i++) {
      password.write(allChars[random.nextInt(allChars.length)]);
    }

    // Shuffle the password
    final chars = password.toString().split('');
    chars.shuffle(random);
    return chars.join();
  }

  Future<void> _onFinish() async {
    if (!_formKey.currentState!.validate()) return;

    // For email sign-in, verify passwords match
    if (!widget.isGoogle) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Determine password
      final password = widget.isGoogle
          ? _generateSecurePassword()
          : _passwordController.text;

      // Submit to BLoC
      context.read<AuthBloc>().add(
        AuthAddDetails(
          username: _usernameController.text.trim(),
          firstName: widget.isGoogle ? _firstNameController.text.trim() : null,
          lastName: widget.isGoogle ? _lastNameController.text.trim() : null,
          password: password,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
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
          context.go('/home');
        } else if (state is AuthFailure) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
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
                  AddDetailsHeader(isGoogle: widget.isGoogle),
                  const SizedBox(height: 32),

                  // Conditional fields based on auth type
                  if (widget.isGoogle) ...[
                    // Google Sign-in: First name, Last name, Username
                    AuthTextField.firstName(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _generateUniqueUsername(),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField.lastName(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _generateUniqueUsername(),
                    ),
                  ] else ...[
                    // Email Sign-in: Password, Confirm password
                    AuthPasswordField.signup(
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AuthPasswordField.confirm(
                      controller: _confirmPasswordController,
                      passwordController: _passwordController,
                      textInputAction: TextInputAction.next,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Username field with loading indicator
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      AuthTextField.username(
                        controller: _usernameController,
                        textInputAction: TextInputAction.done,
                        onRefresh: widget.isGoogle
                            ? _generateUniqueUsername
                            : null,
                        onSubmitted: (_) => _onFinish(),
                      ),
                      if (_isGeneratingUsername)
                        const Positioned(
                          right: 48,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  AuthSubmitButton.finish(
                    isLoading: _isLoading,
                    onPressed: _onFinish,
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
