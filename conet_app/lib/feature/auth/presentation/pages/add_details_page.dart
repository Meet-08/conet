import 'dart:math';

import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/academic_info_form.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/auth/constants/constant.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_password_field.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_submit_button.dart';
import 'package:conet_app/feature/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  int _currentStep = 0;

  bool _isLoading = false;
  bool _isGeneratingUsername = false;

  String? _selectedCollege;
  String? _selectedCourse;
  String? _selectedDegree;
  int? _selectedStartYear;
  int? _selectedEndYear;

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
    if (_isLoading) return;

    final basicFormState = _basicFormKey.currentState;
    if (basicFormState == null || !basicFormState.validate()) return;
    setState(() => _currentStep = 1);
  }

  Future<void> _onFinish() async {
    if (_isLoading) return;

    final academicFormState = _academicFormKey.currentState;
    if (academicFormState == null) {
      AppToast.showError(
        context,
        'Academic form is not ready. Please try again.',
      );
      return;
    }

    if (!academicFormState.validate()) return;

    final college = _selectedCollege?.trim();
    final degree = _selectedDegree?.trim();
    final course = _selectedCourse?.trim();
    final startYear = _selectedStartYear;
    final endYear = _selectedEndYear;

    if (college == null || degree == null || course == null) {
      AppToast.showError(context, 'Please complete your academic details');
      return;
    }

    // For email sign-in, verify passwords match
    if (!widget.isGoogle) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppToast.showError(context, 'Passwords do not match');
        return;
      }
    }

    final password = widget.isGoogle
        ? _generateSecurePassword()
        : _passwordController.text;

    setState(() => _isLoading = true);

    context.read<AuthBloc>().add(
      AuthAddDetails(
        username: _usernameController.text.trim(),
        firstName: widget.isGoogle ? _firstNameController.text.trim() : null,
        lastName: widget.isGoogle ? _lastNameController.text.trim() : null,
        password: password,
        collegeName: college,
        degree: degree,
        course: course,
        startYear: startYear,
        endYear: endYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final title = _currentStep == 0 ? 'Almost there!' : 'Academic Details';
    final subtitle = _currentStep == 0
        ? 'Confirm your details to get started'
        : 'Helps show relevant posts and events';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          if (mounted) {
            setState(() => _isLoading = true);
          }
          return;
        }

        if (state is AuthFailure) {
          if (mounted) {
            AppToast.showError(context, state.message);
            setState(() => _isLoading = false);
          }
          return;
        }

        if (state is AuthSuccess) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: semantic.backgroundSecondary,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: semantic.backgroundSecondary,
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
                  onPressed: () {
                    if (_currentStep == 1) {
                      setState(() => _currentStep = 0);
                      return;
                    }
                    context.read<AuthBloc>().add(AuthLogout());
                  },
                  child: FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    size: AppTypographyTokens.size16,
                    color: semantic.iconOnBrand,
                  ),
                ),
              ),

              const Text('Back', style: AppTextStyles.button),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingH1),
                const SizedBox(height: AppSpace.s8),
                Text(subtitle, style: AppTextStyles.caption),
                const SizedBox(height: AppSpace.s24),
                SingleChildScrollView(
                  child: _currentStep == 0
                      ? _buildBasicDetailsSection()
                      : _buildAcademicSection(),
                ),
                const SizedBox(height: AppSpace.s20),
                _buildContinueButton(context),
                const SizedBox(height: AppSpace.s24),
              ],
            ),
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
            const SizedBox(height: AppSpace.s20),
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
            const SizedBox(height: AppSpace.s20),
            AuthPasswordField.confirm(
              controller: _confirmPasswordController,
              passwordController: _passwordController,
              textInputAction: TextInputAction.next,
            ),
          ],
          const SizedBox(height: AppSpace.s20),
          AuthTextField(
            label: 'Username',
            hintText: '',
            helperText: "Username is unique and can't be changed later",
            controller: _usernameController,
            suffixIcon: _isGeneratingUsername
                ? const Padding(
                    padding: EdgeInsets.all(AppSpace.s12),
                    child: Loader(size: 16, strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _generateUniqueUsername,
                    icon: FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      size: AppTypographyTokens.size16,
                      color: context.semanticColors.iconSecondary,
                    ),
                  ),
            validator: _validateUsername,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onContinueToAcademic(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection() {
    return AcademicInfoForm(
      key: ValueKey(_academicFormKey),
      formKey: _academicFormKey,
      initialCollege: _selectedCollege,
      initialDegree: _selectedDegree,
      initialCourse: _selectedCourse,
      initialStartYear: _selectedStartYear,
      initialEndYear: _selectedEndYear,
      isCreationMode: false,
      isLoading: _isLoading,
      showErrors: true,
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
              _selectedStartYear = startYear;
              _selectedEndYear = endYear;
            });
          },
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return AuthSubmitButton.continue_(
      isLoading: _isLoading,
      onPressed: _currentStep == 0 ? _onContinueToAcademic : _onFinish,
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Username must be 20 characters or less';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }
}
