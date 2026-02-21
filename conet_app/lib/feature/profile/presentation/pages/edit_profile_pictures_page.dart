import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class EditProfilePicturesPage extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfilePicturesPage({super.key, required this.userProfile});

  @override
  State<EditProfilePicturesPage> createState() =>
      _EditProfilePicturesPageState();
}

class _EditProfilePicturesPageState extends State<EditProfilePicturesPage> {
  PlatformFile? _profileImage;
  PlatformFile? _bannerImage;
  bool _hasUpdated = false;

  Future<void> _pickImage(bool isProfile) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        if (isProfile) {
          _profileImage = result.files.first;
        } else {
          _bannerImage = result.files.first;
        }
      });
    }
  }

  void _saveImages(BuildContext context) {
    if (_profileImage == null && _bannerImage == null) return;

    context.read<ProfileBloc>().add(
      ProfileUpdatePicturesEvent(
        profilePic: _profileImage,
        bannerImage: _bannerImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          AppToast.showSuccess(context, 'Images updated successfully');
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
              title: const Text('Profile Pictures'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed:
                        (isLoading ||
                            (_profileImage == null && _bannerImage == null))
                        ? null
                        : () => _saveImages(context),
                    child: isLoading
                        ? const Loader(size: 20, strokeWidth: 2)
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Picture',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => _pickImage(true),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null
                                ? (kIsWeb
                                      ? MemoryImage(_profileImage!.bytes!)
                                      : FileImage(File(_profileImage!.path!))
                                            as ImageProvider)
                                : (widget.userProfile.profilePicUrl != null
                                      ? CachedNetworkImageProvider(
                                          widget.userProfile.profilePicUrl!,
                                        )
                                      : null),
                            child:
                                (_profileImage == null &&
                                    widget.userProfile.profilePicUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Banner Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: _bannerImage != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? MemoryImage(_bannerImage!.bytes!)
                                    : FileImage(File(_bannerImage!.path!))
                                          as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : (widget.userProfile.bannerImageUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        widget.userProfile.bannerImageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child:
                          (_bannerImage == null &&
                              widget.userProfile.bannerImageUrl == null)
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to upload banner',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
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
