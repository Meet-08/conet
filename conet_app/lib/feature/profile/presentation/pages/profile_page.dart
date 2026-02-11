import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:conet_app/feature/profile/presentation/widgets/interests_section.dart';
import 'package:conet_app/feature/profile/presentation/widgets/profile_app_bar.dart';
import 'package:conet_app/feature/profile/presentation/widgets/profile_header_card.dart';
import 'package:conet_app/feature/profile/presentation/widgets/profile_stats_card.dart';
import 'package:conet_app/feature/profile/presentation/widgets/social_links_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is AppUserAuthenticated) {
      context.read<ProfileBloc>().add(
        ProfileGetEvent(uid: appUserState.user.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            _loadProfile();
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileUpdateFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.userProfile;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeaderCard(userProfile: profile),
                  const SizedBox(height: 16),
                  if (profile.interests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InterestsSection(interests: profile.interests),
                    ),
                  const SizedBox(height: 16),
                  if (profile.socialLinks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SocialLinksSection(
                        socialLinks: profile.socialLinks,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ProfileStatsCard(
                      followingCount: profile.followingCount,
                      followerCount: profile.followerCount,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Posts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }

          return const Center(child: Text('Loading profile...'));
        },
      ),
    );
  }
}
