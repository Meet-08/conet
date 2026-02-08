import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';

class ConversationList extends StatelessWidget {
  final List<Conversation> conversations;

  const ConversationList({super.key, required this.conversations});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationTile(conversation: conversation);
      },
    );
  }
}
