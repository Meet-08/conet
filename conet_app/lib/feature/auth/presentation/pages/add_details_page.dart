import 'dart:math';

import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/academic_info_form.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/auth/constants/constant.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/add_details/add_details_header.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_password_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_submit_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_academic_info.dart';
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
  final _basicFormKey = GlobalKey<FormState>();
  final _academicFormKey = GlobalKey<FormState>();

  // Google sign-in fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Email sign-in fields
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Common field
  final _usernameController = TextEditingController();
  final _courseMajorController = TextEditingController();

  int _currentStep = 0;

  bool _isLoading = false;
  bool _isGeneratingUsername = false;

  String? _selectedCollege;
  String? _selectedCourse;
  String? _selectedDegree;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSuggestedUsername();
    });
  }

  Future<void> _initializeSuggestedUsername() async {
    if (widget.isGoogle) {
      await _prefillGoogleNameAndGenerateUsername();
      return;
    }

    await _generateUniqueUsername();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _courseMajorController.dispose();
    super.dispose();
  }

  Future<void> _prefillGoogleNameAndGenerateUsername() async {
    final supabase = serviceLocator<SupabaseClient>();
    final metadata = supabase.auth.currentSession?.user.userMetadata;

    if (metadata == null) return;

    final givenName = _extractMetadataString(metadata, 'given_name');
    final familyName = _extractMetadataString(metadata, 'family_name');
    final fullName =
        _extractMetadataString(metadata, 'full_name') ??
        _extractMetadataString(metadata, 'name');

    String firstName = givenName ?? '';
    String lastName = familyName ?? '';

    if (firstName.isEmpty && fullName != null && fullName.isNotEmpty) {
      final split = _splitFullName(fullName);
      firstName = split.$1;
      lastName = split.$2;
    }

    if (firstName.isEmpty) return;

    _firstNameController.text = firstName;
    _lastNameController.text = lastName;
    await _generateUniqueUsername();
  }

  String? _extractMetadataString(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  (String, String) _splitFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');

    return (parts.first, parts.sublist(1).join(' '));
  }

  String _extractEmailPrefix(String email) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return '';

    final localPart = trimmedEmail.split('@').first;
    return localPart.split('+').first;
  }

  String _sanitizeUsernamePart(String value) {
    if (value.trim().isEmpty) return '';

    final withUnderscores = value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s.-]+'),
      '_',
    );

    final sanitized = withUnderscores
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return sanitized;
  }

  String _normalizeUsernameBase(String base) {
    const fallback = 'user';

    if (base.isEmpty) {
      return fallback;
    }

    if (base.length >= 3) {
      return base;
    }

    return (base + fallback).substring(0, 3);
  }

  String _buildUsernameBase() {
    final supabase = serviceLocator<SupabaseClient>();
    final metadata = supabase.auth.currentSession?.user.userMetadata;

    final firstNameSeed = _sanitizeUsernamePart(_firstNameController.text);
    final lastNameSeed = _sanitizeUsernamePart(_lastNameController.text);

    if (firstNameSeed.isNotEmpty) {
      return _normalizeUsernameBase(
        '$firstNameSeed${lastNameSeed.isEmpty ? '' : lastNameSeed[0]}',
      );
    }

    if (metadata != null) {
      final metadataFirstName =
          _extractMetadataString(metadata, 'first_name') ??
          _extractMetadataString(metadata, 'given_name') ??
          _extractMetadataString(metadata, 'name') ??
          '';
      final metadataLastName =
          _extractMetadataString(metadata, 'last_name') ??
          _extractMetadataString(metadata, 'family_name') ??
          '';

      final sanitizedFirst = _sanitizeUsernamePart(metadataFirstName);
      final sanitizedLast = _sanitizeUsernamePart(metadataLastName);

      if (sanitizedFirst.isNotEmpty) {
        return _normalizeUsernameBase(
          '$sanitizedFirst${sanitizedLast.isEmpty ? '' : sanitizedLast[0]}',
        );
      }
    }

    final emailSeed = _sanitizeUsernamePart(
      _extractEmailPrefix(supabase.auth.currentUser?.email ?? ''),
    );

    return _normalizeUsernameBase(emailSeed);
  }

  /// Generates a unique username and validates with Supabase
  Future<void> _generateUniqueUsername() async {
    const maxUsernameLength = 20;
    final base = _buildUsernameBase();

    setState(() => _isGeneratingUsername = true);

    try {
      bool isAvailable = false;
      int attempts = 0;
      const maxAttempts = 5;
      final random = Random.secure();

      final supabase = serviceLocator<SupabaseClient>();

      while (!isAvailable && attempts < maxAttempts) {
        final suffix = (1000 + random.nextInt(9000)).toString();
        final maxBaseLength = maxUsernameLength - suffix.length;
        final basePart = base.length > maxBaseLength
            ? base.substring(0, maxBaseLength)
            : base;
        final username = '$basePart$suffix';

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
        final suffix = (DateTime.now().millisecondsSinceEpoch % 100000)
            .toString();
        final maxBaseLength = maxUsernameLength - suffix.length;
        final basePart = base.length > maxBaseLength
            ? base.substring(0, maxBaseLength)
            : base;
        _usernameController.text = '$basePart$suffix';
      }
    } catch (e) {
      // Fallback to simple generation on error
      final suffix = (DateTime.now().millisecondsSinceEpoch % 10000).toString();
      const maxBaseLength = maxUsernameLength - 4;
      final basePart = base.length > maxBaseLength
          ? base.substring(0, maxBaseLength)
          : base;
      _usernameController.text = '$basePart$suffix';
    } finally {
      if (mounted) {
        setState(() => _isGeneratingUsername = false);
      }
    }
  }

  /// Generates a random secure password for Google sign-in users
  String _generateSecurePassword() {
    const length = AuthConstants.generatedPasswordLength;
    const lowercase = AuthConstants.lowercaseChars;
    const uppercase = AuthConstants.uppercaseChars;
    const numbers = AuthConstants.numberChars;
    const special = AuthConstants.specialChars;
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

  void _onContinueToAcademic() {
    if (!_basicFormKey.currentState!.validate()) return;
    setState(() => _currentStep = 1);
  }

  Future<void> _onFinish() async {
    if (!_academicFormKey.currentState!.validate()) return;

    if (!_basicFormKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    // For email sign-in, verify passwords match
    if (!widget.isGoogle) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppToast.showError(context, 'Passwords do not match');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Determine password
      final password = widget.isGoogle
          ? _generateSecurePassword()
          : _passwordController.text;

      final addDetailsUseCase = serviceLocator<UserAddDetails>();
      final updateAcademicUseCase = serviceLocator<ProfileUpdateAcademicInfo>();

      final basicResult = await addDetailsUseCase(
        username: _usernameController.text.trim(),
        firstName: widget.isGoogle ? _firstNameController.text.trim() : null,
        lastName: widget.isGoogle ? _lastNameController.text.trim() : null,
        password: password,
      );

      final basicFailure = basicResult.fold((failure) => failure, (_) => null);
      if (basicFailure != null) {
        if (mounted) {
          AppToast.showError(context, basicFailure.message);
          setState(() => _isLoading = false);
        }
        return;
      }

      final academicResult = await updateAcademicUseCase(
        collegeName: _selectedCollege!,
        degree: _selectedDegree!,
        course: _selectedCourse!,
      );

      final academicFailure = academicResult.fold(
        (failure) => failure,
        (_) => null,
      );

      if (academicFailure != null) {
        if (mounted) {
          AppToast.showError(context, academicFailure.message);
          setState(() => _isLoading = false);
        }
        return;
      }

      if (mounted) {
        context.read<AuthBloc>().add(AuthIsUserLoggedIn());
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to save: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AddDetailsHeader(
                isGoogle: widget.isGoogle,
                title: _currentStep == 0
                    ? 'Complete Your Profile'
                    : 'Welcome to Conet!',
                subtitle: _currentStep == 0
                    ? (widget.isGoogle
                          ? 'Add your name and choose a username'
                          : 'Set up your password and username')
                    : "Let's personalize your experience",
                onBack: () {
                  if (_currentStep == 1) {
                    setState(() => _currentStep = 0);
                    return;
                  }
                  context.read<AuthBloc>().add(AuthLogout());
                },
              ),
              const SizedBox(height: 20),
              IndexedStack(
                index: _currentStep,
                children: [
                  _buildBasicDetailsSection(),
                  _buildAcademicSection(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicDetailsSection() {
    return Form(
      key: _basicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isGoogle) ...[
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
          Stack(
            alignment: Alignment.centerRight,
            children: [
              AuthTextField.username(
                controller: _usernameController,
                textInputAction: TextInputAction.done,
                onRefresh: _generateUniqueUsername,
                onSubmitted: (_) => _onContinueToAcademic(),
              ),
              if (_isGeneratingUsername)
                const Positioned(
                  right: 48,
                  child: Loader(size: 16, strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 32),
          AuthSubmitButton.continue_(
            isLoading: _isLoading,
            onPressed: _onContinueToAcademic,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AcademicInfoForm(
          key: ValueKey(_academicFormKey),
          formKey: _academicFormKey,
          initialCollege: _selectedCollege,
          initialDegree: _selectedDegree,
          initialCourse: _selectedCourse,
          isCreationMode: true,
          isLoading: _isLoading,
          onChanged:
              ({
                required college,
                required degree,
                required course,
                required startYear,
                required endYear,
              }) {
                setState(() {
                  _selectedCollege = college;
                  _selectedDegree = degree;
                  _selectedCourse = course;
                });
              },
        ),
        const SizedBox(height: 24),
        AuthSubmitButton.finish(isLoading: _isLoading, onPressed: _onFinish),
      ],
    );
  }
}
