import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_connections_bloc.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum ProfileConnectionsInitialTab { following, followers }

class FollowersFollowingPage extends StatelessWidget {
  final String userId;
  final ProfileConnectionsInitialTab initialTab;

  const FollowersFollowingPage({
    super.key,
    required this.userId,
    this.initialTab = ProfileConnectionsInitialTab.followers,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<ProfileConnectionsBloc>()
            ..add(ProfileConnectionsLoadRequested(uid: userId)),
      child: _FollowersFollowingView(userId: userId, initialTab: initialTab),
    );
  }
}

class _FollowersFollowingView extends StatelessWidget {
  final String userId;
  final ProfileConnectionsInitialTab initialTab;

  const _FollowersFollowingView({
    required this.userId,
    required this.initialTab,
  });

  @override
  Widget build(BuildContext context) {
    final initialIndex = initialTab == ProfileConnectionsInitialTab.following
        ? 0
        : 1;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Following'),
              Tab(text: 'Followers'),
            ],
          ),
        ),
        body: BlocBuilder<ProfileConnectionsBloc, ProfileConnectionsState>(
          builder: (context, state) {
            if (state is ProfileConnectionsInitial ||
                state is ProfileConnectionsLoading) {
              return const Center(child: Loader());
            }

            if (state is ProfileConnectionsFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.error,
                      style: AppTextStyles.bodyDefault.copyWith(
                        color: Theme.of(
                          context,
                        ).extension<AppSemanticColors>()!.textError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProfileConnectionsBloc>().add(
                          ProfileConnectionsLoadRequested(uid: userId),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final loadedState = state as ProfileConnectionsLoaded;
            return TabBarView(
              children: [
                _ConnectionList(users: loadedState.following),
                _ConnectionList(users: loadedState.followers),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionList extends StatelessWidget {
  final List<User> users;

  const _ConnectionList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: AppTextStyles.bodyDefault.copyWith(
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textSecondary,
          ),
        ),
      );
    }

    final appUserState = context.read<AppUserCubit>().state;
    final currentUserId = appUserState is AppUserAuthenticated
        ? appUserState.user.id
        : null;

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = users[index];
        final fullName = '${user.firstName} ${user.lastName}'.trim().isNotEmpty
            ? '${user.firstName} ${user.lastName}'.trim()
            : user.username;

        return ListTile(
          onTap: () => context.push('/user-profile', extra: user.id),
          leading: CustomCircleAvatar(
            size: CustomCircleAvatarSize.medium,
            imageUrl: user.profilePicUrl,
            displayName: fullName,
          ),
          title: Text(
            fullName,
            style: AppTextStyles.bodyDefault.copyWith(
              color: Theme.of(
                context,
              ).extension<AppSemanticColors>()!.textPrimary,
            ),
          ),
          subtitle: Text(
            user.username.isEmpty ? '' : '@${user.username}',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(
                context,
              ).extension<AppSemanticColors>()!.textSecondary,
            ),
          ),
          trailing: currentUserId == user.id
              ? Text(
                  'You',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppSemanticColors>()!.textSecondary,
                  ),
                )
              : null,
        );
      },
    );
  }
}
