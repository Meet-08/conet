import 'package:flutter/material.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_input_bar.dart';

class ChatDetailPage extends StatelessWidget {
  const ChatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatAppBar(),
      body: Column(
        children: const [
          Expanded(
            child: ChatMessageList(),
          ),
          ChatInputBar(),
        ],
      ),
    );
  }
}
