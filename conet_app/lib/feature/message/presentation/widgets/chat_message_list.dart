import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final String? currentUserId;
  final bool isGroupConversation;
  final bool isDirectConversation;
  final List<GroupMember> groupMembers;
  final ScrollController? scrollController;
  final bool isFetchingHistory;
  final MessageStatus messageStatus;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.isGroupConversation = false,
    this.isDirectConversation = false,
    this.groupMembers = const [],
    this.scrollController,
    required this.messageStatus,
    this.isFetchingHistory = false,
  });

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeading(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    if (messageStatus == MessageStatus.loading) {
      return const Center(child: Loader());
    }

    if (messageStatus == MessageStatus.success && messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: AppTextStyles.bodyDefault.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final sorted = [...messages]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groupMembersById = {
      for (final member in groupMembers) member.id: member,
    };

    String? latestOutgoingMessageId;
    if (currentUserId != null) {
      for (final message in sorted) {
        if (message.senderId == currentUserId) {
          latestOutgoingMessageId = message.id;
          break;
        }
      }
    }

    final totalCount = sorted.length + (isFetchingHistory ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.all(12),
      cacheExtent: 400,
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (isFetchingHistory && index == sorted.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final message = sorted[index];
        final isMe = currentUserId != null && message.senderId == currentUserId;
        final sender = groupMembersById[message.senderId];
        final hasOlderMessage = index < sorted.length - 1;
        final shouldShowDateHeading =
            !hasOlderMessage ||
            !_isSameDate(message.createdAt, sorted[index + 1].createdAt);
        final time = TimeOfDay.fromDateTime(
          message.createdAt.toLocal(),
        ).format(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shouldShowDateHeading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDateHeading(message.createdAt),
                      style: AppTextStyles.micro.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ChatMessageBubble(
              text: message.content,
              time: time,
              isMe: isMe,
              mediaUrls: message.mediaUrls,
              status: message.status,
              senderName: sender?.displayName,
              senderImageUrl: sender?.profilePicUrl,
              showSeenStatus:
                  isDirectConversation &&
                  isMe &&
                  message.id == latestOutgoingMessageId,
              isSeen: message.isRead,
            ),
          ],
        );
      },
    );
  }
}
