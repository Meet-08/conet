import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_input_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailPage extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MessageBloc>();
    bloc.add(MessageWatchStarted(widget.conversation.id));
    bloc.add(MessageMarkAsReadRequested(widget.conversation.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<MessageBloc>().add(
      MessageSent(conversationId: widget.conversation.id, content: text),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: ChatAppBar(otherUser: widget.conversation.otherUser),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                return ChatMessageList(
                  messages: state.messages,
                  currentUserId: currentUserId,
                );
              },
            ),
          ),
          ChatInputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}
