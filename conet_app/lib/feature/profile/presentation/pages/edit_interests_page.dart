import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class EditInterestsPage extends StatefulWidget {
  final UserProfile userProfile;

  const EditInterestsPage({super.key, required this.userProfile});

  @override
  State<EditInterestsPage> createState() => _EditInterestsPageState();
}

class _EditInterestsPageState extends State<EditInterestsPage> {
  static const List<String> _availableInterests = [
    'Web Development',
    'Machine Learning',
    'UI/UX Design',
    'Data Science',
    'Photography',
    'Entrepreneurship',
    'Mobile Development',
    'Cloud Computing',
    'Cybersecurity',
    'Game Development',
    'Blockchain',
    'AI Research',
    'DevOps',
    'Product Management',
    'Digital Marketing',
    'Content Writing',
  ];

  late final Set<String> _selectedInterests;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set.from(widget.userProfile.interests);
  }

  void _save(BuildContext context) {
    context.read<ProfileBloc>().add(
      ProfileUpdateInterestsEvent(interests: _selectedInterests.toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          AppToast.showSuccess(context, 'Interests updated successfully');

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
              title: const Text('Interests'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select topics you\'re interested in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: _availableInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(
                            interest,
                          );
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedInterests.remove(interest);
                                } else {
                                  _selectedInterests.add(interest);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                            .extension<AppSemanticColors>()!
                                            .borderDefault,
                                ),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                            .extension<AppSemanticColors>()!
                                            .textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
