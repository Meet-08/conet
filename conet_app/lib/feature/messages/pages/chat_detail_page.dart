import 'package:conet_app/feature/messages/widgets/chat_app_bar.dart';
import 'package:conet_app/feature/messages/widgets/chat_input_bar.dart';
import 'package:conet_app/feature/messages/widgets/chat_message_list.dart';
import 'package:flutter/material.dart';

class ChatDetailPage extends StatelessWidget {
  const ChatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ChatAppBar(),
      body: Column(
        children: [
          Expanded(child: ChatMessageList()),
          ChatInputBar(),
        ],
      ),
    );
  }
}
