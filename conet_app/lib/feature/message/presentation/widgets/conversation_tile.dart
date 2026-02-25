import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({super.key, required this.conversation});

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

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

  Widget _buildLastMessagePreview() {
    final hasUnread = conversation.unreadCount > 0;
    final textStyle = TextStyle(
      fontSize: 13.5,
      color: Colors.grey.shade600,
      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
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
          Icon(Icons.photo_camera, size: 16, color: Colors.grey.shade600),
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
    final initials = _getInitials(displayName);
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () {
        context.push('/chat-detail', extra: conversation);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Circle avatar with initials
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors
                  .primaries[displayName.hashCode % Colors.primaries.length]
                  .shade100,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? conversation.isGroup
                        ? Icon(
                            Icons.group,
                            color: Colors
                                .primaries[displayName.hashCode %
                                    Colors.primaries.length]
                                .shade800,
                            size: 20,
                          )
                        : Text(
                            initials,
                            style: TextStyle(
                              color: Colors
                                  .primaries[displayName.hashCode %
                                      Colors.primaries.length]
                                  .shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          )
                  : null,
            ),
            const SizedBox(width: 14),
            // Content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + timestamp row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(conversation.updatedAt),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last message + unread badge row
                  Row(
                    children: [
                      Expanded(child: _buildLastMessagePreview()),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
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
