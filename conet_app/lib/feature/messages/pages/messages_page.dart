import 'package:flutter/material.dart';
import '../widgets/message_app_bar.dart';
import '../widgets/message_filters.dart';
import '../widgets/conversation_list.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MessageAppBar(),
      body: Column(
        children: const [
          MessageFilters(),
          Expanded(
            child: ConversationList(),
          ),
        ],
      ),
    );
  }
}
