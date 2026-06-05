import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:getwidget/components/loader/gf_loader.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    final userState = context.read<AppUserCubit>().state;
    if (userState is AppUserAuthenticated) {
      context.read<ProfileBloc>().add(ProfileGetEvent(uid: userState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Complete Your Profile'),
        centerTitle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateFailure) {
            AppToast.showError(context, state.error);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const GFLoader();
          }
          if (state is ProfileLoaded) {
            final user = state.userProfile;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 8),
                  child: Text(
                    'Add more details to help others connect with you',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.textSecondary,
                    ),
                  ),
                ),
                _ProfileSectionTile(
                  icon: FontAwesomeIcons.camera,
                  title: 'Profile Pictures',
                  subtitle: _getPicturesSubtitle(user),
                  isCompleted: user.profilePicUrl != null,
                  onTap: () =>
                      _navigateAndRefresh('/edit-profile/pictures', user),
                ),
                const SizedBox(height: 12),
                _ProfileSectionTile(
                  icon: FontAwesomeIcons.user,
                  title: 'Personal Info',
                  subtitle: _getPersonalInfoSubtitle(user),
                  isCompleted: _isPersonalInfoComplete(user),
                  onTap: () =>
                      _navigateAndRefresh('/edit-profile/personal-info', user),
                ),
                const SizedBox(height: 12),
                _ProfileSectionTile(
                  icon: FontAwesomeIcons.graduationCap,
                  title: 'Academic Info',
                  subtitle: 'Add your education details',
                  isCompleted: user.academics.isNotEmpty,
                  onTap: () =>
                      _navigateAndRefresh('/edit-profile/academic-info', user),
                ),
                const SizedBox(height: 12),
                _ProfileSectionTile(
                  icon: FontAwesomeIcons.solidUser,
                  title: 'About Me',
                  subtitle: 'Tell others about yourself',
                  isCompleted: user.aboutMe != null && user.aboutMe!.isNotEmpty,
                  onTap: () =>
                      _navigateAndRefresh('/edit-profile/about-me', user),
                ),
                const SizedBox(height: 12),
                _ProfileSectionTile(
                  icon: FontAwesomeIcons.solidHeart,
                  title: 'Interests',
                  subtitle: 'Select your interests',
                  isCompleted: user.interests.isNotEmpty,
                  onTap: () =>
                      _navigateAndRefresh('/edit-profile/interests', user),
                ),
                const SizedBox(height: 12),
                _ProfileSectionTile(
                  icon: FontAwesomeIcons.link,
                  title: 'Social Links',
                  subtitle: 'Add your social profiles',
                  isCompleted: user.socialLinks.isNotEmpty,
                  onTap: () =>
                      _navigateAndRefresh('/edit-profile/social-links', user),
                ),
                const SizedBox(height: 12),
              ],
            );
          }
          if (state is ProfileUpdateFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _refreshProfile() {
    final userState = context.read<AppUserCubit>().state;
    if (userState is AppUserAuthenticated) {
      context.read<ProfileBloc>().add(ProfileGetEvent(uid: userState.user.id));
    }
  }

  String _getPicturesSubtitle(UserProfile user) {
    int count = 0;
    if (user.profilePicUrl != null) count++;
    if (user.bannerImageUrl != null) count++;
    return '$count/2 added';
  }

  String _getPersonalInfoSubtitle(UserProfile user) {
    int completed = 0;
    const total = 3;
    if (user.firstName?.isNotEmpty ?? false) completed++;
    if (user.lastName?.isNotEmpty ?? false) completed++;
    if (user.username?.isNotEmpty ?? false) completed++;
    if (completed == total) return 'Completed';
    return '$completed/$total completed';
  }

  bool _isPersonalInfoComplete(UserProfile user) {
    return (user.firstName?.isNotEmpty ?? false) &&
        (user.lastName?.isNotEmpty ?? false) &&
        (user.username?.isNotEmpty ?? false);
  }

  Future<void> _navigateAndRefresh(String path, UserProfile user) async {
    final result = await context.push(path, extra: user);
    if (result == true) {
      if (mounted) {
        _refreshProfile();
      }
    }
  }
}

class _ProfileSectionTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ProfileSectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.backgroundTertiary,
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                icon,
                size: 22,
                color: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.iconSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FaIcon(
                  FontAwesomeIcons.solidCircleCheck,
                  color: Theme.of(
                    context,
                  ).extension<AppSemanticColors>()!.textSuccess,
                  size: 22,
                ),
              ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              color: Theme.of(
                context,
              ).extension<AppSemanticColors>()!.iconTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
