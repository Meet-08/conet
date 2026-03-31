import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final String? currentUserId;
  final ScrollController? scrollController;
  final bool isFetchingHistory;
  final MessageStatus messageStatus;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.scrollController,
    required this.messageStatus,
    this.isFetchingHistory = false,
  });

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

    final totalCount = sorted.length + (isFetchingHistory ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.all(12),
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
        final time = TimeOfDay.fromDateTime(
          message.createdAt.toLocal(),
        ).format(context);
        return ChatMessageBubble(
          text: message.content,
          time: time,
          isMe: isMe,
          mediaUrls: message.mediaUrls,
          status: message.status,
        );
      },
    );
  }
}
