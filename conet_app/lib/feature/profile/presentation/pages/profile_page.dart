import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
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
    _loadPosts();
  }

  void _loadProfile() {
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is AppUserAuthenticated) {
      context.read<ProfileBloc>().add(
        ProfileGetEvent(uid: appUserState.user.id),
      );
    }
  }

  void _loadPosts() {
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is AppUserAuthenticated) {
      context.read<PostBloc>().add(
        PostGetUserPostsEvent(userId: appUserState.user.id),
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
            return const Center(child: Loader());
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
                      padding: const .symmetric(horizontal: 16),
                      child: SocialLinksSection(
                        socialLinks: profile.socialLinks,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const .symmetric(horizontal: 16),
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
                  BlocBuilder<PostBloc, PostState>(
                    builder: (context, postState) {
                      if (postState is PostLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Loader()),
                        );
                      }
                      if (postState is PostFailure) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              postState.message,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      if (postState is PostLoaded) {
                        if (postState.posts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No posts yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: postState.posts.length,
                          itemBuilder: (ctx, i) =>
                              PostCard(post: postState.posts[i]),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
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
