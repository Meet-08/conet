import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final String? currentUserId;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet'));
    }

    final sorted = [...messages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ListView.builder(
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
        );
      },
    );
  }
}
