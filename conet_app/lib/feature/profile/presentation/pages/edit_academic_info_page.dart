import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EditAcademicInfoPage extends StatefulWidget {
  final UserProfile userProfile;

  const EditAcademicInfoPage({super.key, required this.userProfile});

  @override
  State<EditAcademicInfoPage> createState() => _EditAcademicInfoPageState();
}

class _EditAcademicInfoPageState extends State<EditAcademicInfoPage> {
  late final TextEditingController _collegeController;
  late final TextEditingController _courseController;
  late final TextEditingController _startYearController;
  late final TextEditingController _endYearController;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    final academics = widget.userProfile.academics;
    final firstAcademic = academics.isNotEmpty ? academics.first : null;

    _collegeController = TextEditingController(
      text: firstAcademic?.collegeName ?? '',
    );
    _courseController = TextEditingController(
      text: firstAcademic?.course ?? '',
    );
    _startYearController = TextEditingController(
      text: firstAcademic?.startYear != null
          ? firstAcademic!.startYear.toString()
          : '',
    );
    _endYearController = TextEditingController(
      text: firstAcademic?.endYear != null
          ? firstAcademic!.endYear.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _courseController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final startYear = int.tryParse(_startYearController.text.trim());
    final endYear = int.tryParse(_endYearController.text.trim());

    context.read<ProfileBloc>().add(
      ProfileUpdateAcademicInfoEvent(
        collegeName: _collegeController.text.trim(),
        course: _courseController.text.trim(),
        startYear: startYear,
        endYear: endYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          AppToast.showSuccess(context, 'Academic info updated successfully');

          setState(() {
            _hasUpdated = true;
          });
        } else if (state is ProfileUpdateFailure) {
          AppToast.showError(context, state.error);
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoading;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            context.pop(_hasUpdated);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(_hasUpdated),
              ),
              title: const Text('Academic Info'),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton(
                    onPressed: isLoading ? null : () => _save(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const Loader(
                            size: 18,
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'College / University',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _collegeController,
                    hint: 'Stanford University',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Course / Major',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _courseController,
                    hint: 'Electronics Engineering',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Year',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _startYearController,
                              hint: '2023',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Year',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _endYearController,
                              hint: '2027',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
