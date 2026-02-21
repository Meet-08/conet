import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

/// A beautifully designed OTP verification dialog.
class OtpDialog extends StatefulWidget {
  final String email;

  const OtpDialog({super.key, required this.email});

  /// Shows the OTP dialog and returns true if verification was successful.
  static Future<bool?> show(BuildContext context, {required String email}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpDialog(email: email),
    );
  }

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the pin input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isOtpComplete => _pinController.text.length == 6;

  void _onVerify() {
    if (!_isOtpComplete) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    context.read<AuthBloc>().add(
      AuthVerifyOtp(email: widget.email, otp: _pinController.text),
    );
  }

  void _onResendOtp() {
    _pinController.clear();
    _focusNode.requestFocus();
    setState(() => _errorMessage = null);

    context.read<AuthBloc>().add(
      AuthSendOtp(email: widget.email, firstName: '', lastName: null),
    );

    AppToast.showInfo(context, 'OTP resent to your email');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        } else if (state is AuthSuccess) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          if (state.isNewUser) {
            context.go('/add-details', extra: false); // isGoogle = false
          } else {
            context.go('/home');
          }
        } else if (state is AuthFailure) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.lock,
                  size: 32,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Enter the 6-digit code sent to',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              // Pinput OTP Input
              Pinput(
                controller: _pinController,
                focusNode: _focusNode,
                length: 6,
                autofocus: true,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                closeKeyboardWhenCompleted: false,
                onCompleted: (_) => _onVerify(),
                onChanged: (_) => setState(() => _errorMessage = null),
                mainAxisAlignment: MainAxisAlignment.center,
                separatorBuilder: (index) => const SizedBox(width: 8),
                defaultPinTheme: PinTheme(
                  width: 44,
                  height: 44,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 44,
                  height: 44,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
                submittedPinTheme: PinTheme(
                  width: 44,
                  height: 44,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
                errorPinTheme: PinTheme(
                  width: 44,
                  height: 44,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.circleExclamation,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isOtpComplete ? null : _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const Loader(
                          size: 22,
                          strokeWidth: 2.5,
                          color: Colors.white,
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Resend & Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Container(width: 1, height: 16, color: Colors.grey.shade300),
                  TextButton(
                    onPressed: _isLoading ? null : _onResendOtp,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
