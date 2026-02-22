import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final String? currentUserId;
  final ScrollController? scrollController;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet'));
    }

    final sorted = [...messages]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
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
