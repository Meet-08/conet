import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({super.key, required this.conversation});

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  Widget _buildLastMessagePreview(AppSemanticColors colors) {
    final hasUnread = conversation.unreadCount > 0;
    final textStyle = AppTextStyles.bodySmall.copyWith(
      color: colors.textSecondary,
      fontWeight: hasUnread
          ? AppTypographyTokens.weightMedium
          : AppTypographyTokens.weightRegular,
    );

    // 1. Prioritize text content if available
    if (conversation.lastMessage != null &&
        conversation.lastMessage!.isNotEmpty) {
      return Text(
        conversation.lastMessage!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    // 2. Fallback to media indicator
    if (conversation.lastMessageMediaUrls.isNotEmpty) {
      final count = conversation.lastMessageMediaUrls.length;
      return Row(
        children: [
          Icon(Icons.photo_camera, size: 16, color: colors.iconSecondary),
          const SizedBox(width: 4),
          Text(count > 1 ? '$count Photos' : 'Photo', style: textStyle),
        ],
      );
    }

    // 3. Default state
    return Text(
      'Tap to open chat',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.displayName;
    final imageUrl = conversation.displayImageUrl;
    final hasUnread = conversation.unreadCount > 0;
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return InkWell(
      onTap: () {
        context.push('/chat-detail', extra: conversation);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const SizedBox(width: 14),
            // Content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name +  timestamp row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyDefault.copyWith(
                            fontWeight: hasUnread
                                ? AppTypographyTokens.weightBold
                                : AppTypographyTokens.weightSemibold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(conversation.updatedAt),
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last message + unread badge row
                  Row(
                    children: [
                      Expanded(child: _buildLastMessagePreview(colors)),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 20,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.backgroundInfo,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textOnBrand,
                              fontWeight: AppTypographyTokens.weightBold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
