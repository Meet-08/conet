import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/pages/shared_media_page.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ChatParticipantDetailsPage extends StatefulWidget {
  final Conversation conversation;

  const ChatParticipantDetailsPage({super.key, required this.conversation});

  @override
  State<ChatParticipantDetailsPage> createState() =>
      _ChatParticipantDetailsPageState();
}

class _ChatParticipantDetailsPageState
    extends State<ChatParticipantDetailsPage> {
  String get _userId => widget.conversation.otherUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _userId.isEmpty) return;
      context.read<ProfileBloc>().add(ProfileGetEvent(uid: _userId));
    });
  }

  UserProfile? _resolveProfile(ProfileState state) {
    return switch (state) {
      ProfileLoaded(:final userProfile) => userProfile,
      ProfileFollowFailure(:final profile) => profile,
      _ => null,
    };
  }

  String _fullName(UserProfile profile) {
    final firstName = profile.firstName ?? '';
    final lastName = profile.lastName ?? '';
    return '$firstName $lastName'.trim();
  }

  void _toggleFollow(UserProfile profile) {
    final bloc = context.read<ProfileBloc>();
    if (profile.isFollowing) {
      bloc.add(ProfileUnfollowUserEvent(targetUid: profile.id));
    } else {
      bloc.add(ProfileFollowUserEvent(targetUid: profile.id));
    }
  }

  void _showUnavailableMessage(String message) {
    AppToast.showInfo(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>()!;

    if (_userId.isEmpty) {
      return Scaffold(
        backgroundColor: colors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: colors.backgroundSecondary,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Invalid conversation payload')),
      );
    }

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => current is ProfileFollowFailure,
      listener: (context, state) {
        if (state is ProfileFollowFailure) {
          AppToast.showError(context, state.error);
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return Scaffold(
            backgroundColor: colors.backgroundSecondary,
            appBar: AppBar(
              backgroundColor: colors.backgroundSecondary,
              leading: IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Loader()),
          );
        }

        if (state is ProfileUpdateFailure) {
          return Scaffold(
            backgroundColor: colors.backgroundSecondary,
            appBar: AppBar(
              backgroundColor: colors.backgroundSecondary,
              leading: IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyDefault.copyWith(
                        color: colors.textError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ProfileBloc>().add(
                        ProfileGetEvent(uid: _userId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = _resolveProfile(state);
        if (profile == null) {
          return Scaffold(
            backgroundColor: colors.backgroundSecondary,
            appBar: AppBar(
              backgroundColor: colors.backgroundSecondary,
              leading: IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Text(
                'Profile details unavailable',
                style: AppTextStyles.bodyDefault.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          );
        }

        final fullName = _fullName(profile).isNotEmpty
            ? _fullName(profile)
            : widget.conversation.displayName;
        final userName = profile.username?.trim() ?? '';
        final profileImageUrl =
            profile.profilePicUrl ?? widget.conversation.displayImageUrl;

        return Scaffold(
          backgroundColor: colors.backgroundSecondary,
          appBar: AppBar(
            backgroundColor: colors.backgroundSecondary,
            elevation: 0,
            leading: IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CustomCircleAvatar(
                        size: CustomCircleAvatarSize.medium,
                        radius: 42,
                        imageUrl: profileImageUrl,
                        displayName: fullName,
                        userId: profile.id,
                        backgroundColor: colors.backgroundTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingH3.copyWith(
                          color: colors.textPrimary,
                          fontWeight: AppTypographyTokens.weightBold,
                        ),
                      ),
                      if (userName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$userName',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _toggleFollow(profile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: profile.isFollowing
                                ? colors.surfaceBase
                                : theme.colorScheme.primary,
                            foregroundColor: profile.isFollowing
                                ? colors.textPrimary
                                : theme.colorScheme.onPrimary,
                            side: profile.isFollowing
                                ? BorderSide(color: colors.borderDefault)
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: AppTextStyles.label,
                          ),
                          child: Text(
                            profile.isFollowing ? 'Following' : 'Follow',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ParticipantSettingTile(
                  title: 'Shared media, links and docs',
                  onTap: () {
                    final conv = widget.conversation;
                    if (conv.id.isNotEmpty) {
                      context.read<MessageBloc>().add(
                        MessageFetchSharedContentRequested(
                          conversationId: conv.id,
                          type: 'media',
                        ),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SharedMediaPage(
                            conversationId: conv.id,
                            type: 'media',
                          ),
                        ),
                      );
                    } else {
                      _showUnavailableMessage(
                        'Shared items are not available yet.',
                      );
                    }
                  },
                ),
                _ParticipantSettingTile(
                  title: 'Notification',
                  onTap: () => _showUnavailableMessage(
                    'Notification settings are not available yet.',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ParticipantSettingTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ParticipantSettingTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyDefault.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 14,
                color: colors.iconTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
