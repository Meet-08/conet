import 'package:conet_app/core/common/cubit/presence_cubit.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/online_indicator.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Conversation conversation;

  const ChatAppBar({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.displayName;
    final imageUrl = conversation.displayImageUrl;

    if (conversation.isGroup) {
      return _buildGroupAppBar(context, displayName, imageUrl);
    }

    return _buildDirectAppBar(context, displayName, imageUrl);
  }

  AppBar _buildGroupAppBar(
    BuildContext context,
    String displayName,
    String? imageUrl,
  ) {
    final memberCount = conversation.members.length;
    final subtitle = memberCount > 0 ? '$memberCount members' : 'Group';
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
      title: GestureDetector(
        onTap: () => context.push('/group-details', extra: conversation),
        child: Row(
          children: [
            CustomCircleAvatar(
              radius: 24,
              imageUrl: imageUrl,
              displayName: displayName,
              backgroundColor: Colors
                  .primaries[displayName.hashCode % Colors.primaries.length]
                  .shade100,
              shape: conversation.isEvent
                  ? AvatarShape.square
                  : AvatarShape.circle,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildDirectAppBar(
    BuildContext context,
    String displayName,
    String? imageUrl,
  ) {
    final otherUser = conversation.otherUser;
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          if (otherUser != null)
            BlocSelector<PresenceCubit, Set<String>, bool>(
              selector: (onlineIds) => onlineIds.contains(otherUser.id),
              builder: (context, isOnline) {
                return GestureDetector(
                  onTap: () =>
                      context.push('/user-profile', extra: otherUser.id),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomCircleAvatar(
                        size: CustomCircleAvatarSize.medium,
                        imageUrl: imageUrl,
                        displayName: displayName,
                        userId: otherUser.id,
                        backgroundColor: Colors
                            .primaries[displayName.hashCode %
                                Colors.primaries.length]
                            .shade100,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: OnlineIndicator(isOnline: isOnline),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            CustomCircleAvatar(
              radius: 24,
              imageUrl: imageUrl,
              displayName: displayName,
              backgroundColor: Colors
                  .primaries[displayName.hashCode % Colors.primaries.length]
                  .shade100,
            ),
          const SizedBox(width: 8),
          // Name and online status text
          if (otherUser != null)
            BlocSelector<PresenceCubit, Set<String>, bool>(
              selector: (onlineIds) => onlineIds.contains(otherUser.id),
              builder: (context, isOnline) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: AppTextStyles.micro.copyWith(
                        color: isOnline
                            ? colors.textSuccess
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            )
          else
            Text(
              displayName,
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
