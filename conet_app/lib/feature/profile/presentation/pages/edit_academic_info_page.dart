import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/academic_info_form.dart';
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
  late final GlobalKey<FormState> _formKey;
  late final GlobalKey _academicFormStateKey;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _academicFormStateKey = GlobalKey();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Please fill all required fields');
      return;
    }

    final formState = _academicFormStateKey.currentState as dynamic;
    final values = formState.getValues();

    if (values.college == null ||
        values.degree == null ||
        values.course == null) {
      AppToast.showError(context, 'Please fill all required fields');
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileUpdateAcademicInfoEvent(
        collegeName: values.college as String,
        degree: values.degree as String,
        course: values.course as String,
        startYear: values.startYear as int?,
        endYear: values.endYear as int?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academics = widget.userProfile.academics;
    final firstAcademic = academics.isNotEmpty ? academics.first : null;

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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
              child: AcademicInfoForm(
                key: _academicFormStateKey,
                formKey: _formKey,
                initialCollege: firstAcademic?.collegeName,
                initialDegree: firstAcademic?.degree,
                initialCourse: firstAcademic?.course,
                initialStartYear: firstAcademic?.startYear,
                initialEndYear: firstAcademic?.endYear,
                isCreationMode: false,
                isLoading: isLoading,
                onChanged:
                    ({
                      required college,
                      required degree,
                      required course,
                      required startYear,
                      required endYear,
                    }) {
                      // No-op for changes, data is managed by AcademicInfoForm state
                    },
              ),
            ),
          ),
        );
      },
    );
  }
}
