import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/payment/presentation/bloc/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetupOrganizerAccountPage extends StatefulWidget {
  const SetupOrganizerAccountPage({super.key});

  @override
  State<SetupOrganizerAccountPage> createState() =>
      _SetupOrganizerAccountPageState();
}

class _SetupOrganizerAccountPageState extends State<SetupOrganizerAccountPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankController = TextEditingController();
  final _panController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _street1Controller = TextEditingController();
  final _street2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'IN');

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _bankController.dispose();
    _panController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _street1Controller.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<PaymentBloc>().add(
        PaymentCreateOrganizerAccountEvent(
          accountHolderName: _nameController.text.trim(),
          accountNumber: _accountController.text.trim(),
          ifscCode: _ifscController.text.trim(),
          bankName: _bankController.text.trim(),
          pan: _panController.text.trim(),
          title: _titleController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          street1: _street1Controller.text.trim(),
          street2: _street2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim().toUpperCase(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Organizer Account')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentCreateOrganizerSuccess) {
            AppToast.showSuccess(
              context,
              'Organizer account linked successfully!',
            );
            Navigator.of(context).pop(true);
          } else if (state is PaymentFailure) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is PaymentLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Link your bank account to receive event payments via Razorpay Route.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildField(_nameController, 'Account Holder Name'),
                const SizedBox(height: 12),
                _buildField(_accountController, 'Account Number'),
                const SizedBox(height: 12),
                _buildField(_ifscController, 'IFSC Code', isUppercase: true),
                const SizedBox(height: 12),
                _buildField(_bankController, 'Bank Name'),
                const SizedBox(height: 12),
                _buildField(_panController, 'PAN', isUppercase: true),
                const SizedBox(height: 12),
                _buildField(_titleController, 'Business Title / Legal Name'),
                const SizedBox(height: 12),
                _buildField(_street1Controller, 'Address Line 1'),
                const SizedBox(height: 12),
                _buildField(
                  _street2Controller,
                  'Address Line 2 (Optional)',
                  isRequired: false,
                ),
                const SizedBox(height: 12),
                _buildField(_cityController, 'City'),
                const SizedBox(height: 12),
                _buildField(_stateController, 'State'),
                const SizedBox(height: 12),
                _buildField(
                  _postalCodeController,
                  'Postal Code',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildField(
                  _countryController,
                  'Country',
                  isUppercase: true,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _buildField(_phoneController, 'Phone Number', isPhone: true),
                const SizedBox(height: 12),
                _buildField(_emailController, 'Email', isEmail: true),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save & Link Account'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool isUppercase = false,
    bool isPhone = false,
    bool isEmail = false,
    bool isRequired = true,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      textCapitalization: isUppercase
          ? TextCapitalization.characters
          : TextCapitalization.none,
      keyboardType: isPhone
          ? TextInputType.phone
          : isEmail
          ? TextInputType.emailAddress
          : keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
        }

        if (label == 'Postal Code' && (value ?? '').trim().isNotEmpty) {
          final code = value!.trim();
          if (!RegExp(r'^\d{6}$').hasMatch(code)) {
            return 'Postal Code must be 6 digits';
          }
        }

        return null;
      },
    );
  }
}
