import 'package:conet_app/feature/messages/widgets/conversation_list.dart';
import 'package:conet_app/feature/messages/widgets/message_app_bar.dart';
import 'package:conet_app/feature/messages/widgets/message_filters.dart';
import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MessageAppBar(),
      body: Column(
        children: [
          MessageFilters(),
          Expanded(child: ConversationList()),
        ],
      ),
    );
  }
}
