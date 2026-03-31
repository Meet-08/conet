import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';

class ConversationList extends StatelessWidget {
  final List<Conversation> conversations;

  const ConversationList({super.key, required this.conversations});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 70,
        color: colors.borderSubtle,
      ),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationTile(conversation: conversation);
      },
    );
  }
}
