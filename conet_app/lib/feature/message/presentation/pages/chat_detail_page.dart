import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_input_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_list.dart';
import 'package:file_picker/file_picker.dart';
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
  List<PlatformFile> _selectedFiles = [];

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
    if (_controller.text.trim().isEmpty) return;

    context.read<MessageBloc>().add(
      MessageSent(
        conversationId: widget.conversation.id,
        content: _controller.text.trim(),
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      ),
    );
    _controller.clear();
    setState(() {
      _selectedFiles = [];
    });
  }

  Future<void> _pickFiles() async {
    final files = await pickFiles();
    if (files != null) {
      setState(() {
        _selectedFiles = files;
      });
    }
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
          ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
            onFilesSelected: _pickFiles,
          ),
        ],
      ),
    );
  }
}
