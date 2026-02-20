import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class EditAboutMePage extends StatefulWidget {
  final UserProfile userProfile;

  const EditAboutMePage({super.key, required this.userProfile});

  @override
  State<EditAboutMePage> createState() => _EditAboutMePageState();
}

class _EditAboutMePageState extends State<EditAboutMePage> {
  late final TextEditingController _aboutMeController;
  static const int _maxLength = 500;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _aboutMeController = TextEditingController(
      text: widget.userProfile.aboutMe ?? '',
    );
    _aboutMeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    context.read<ProfileBloc>().add(
      ProfileUpdateAboutMeEvent(aboutMe: _aboutMeController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          AppToast.showSuccess(context, 'About me updated successfully');

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
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                onPressed: () => context.pop(_hasUpdated),
              ),
              title: const Text('About Me'),
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
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                    'Tell us about yourself',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aboutMeController,
                    maxLines: 6,
                    maxLength: _maxLength,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) {
                          return null;
                        },
                    decoration: InputDecoration(
                      hintText:
                          'Passionate student interested in technology, innovation, and making a positive impact...',
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
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_aboutMeController.text.length} / $_maxLength characters',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
