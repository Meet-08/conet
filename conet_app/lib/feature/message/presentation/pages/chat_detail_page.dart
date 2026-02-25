import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_input_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatDetailPage extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<PlatformFile> _selectedFiles = [];
  late MessageBloc _messageBloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageBloc = context.read<MessageBloc>();
    _messageBloc.add(MessageWatchStarted(widget.conversation.id));
  }

  @override
  void dispose() {
    _messageBloc.add(MessageWatchStopped(widget.conversation.id));
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final isNearTop = position.pixels >= (position.maxScrollExtent - 120);
    if (isNearTop) {
      _messageBloc.add(MessageFetchHistoryRequested(widget.conversation.id));
    }
  }

  void _sendMessage() {
    final hasText = _controller.text.trim().isNotEmpty;
    final hasFiles = _selectedFiles.isNotEmpty;

    if (!hasText && !hasFiles) return;

    _messageBloc.add(
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

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Reversed list, so 0 is bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(conversation: widget.conversation),
      body: Column(
        children: [
          Expanded(
            child: BlocListener<MessageBloc, MessageState>(
              listenWhen: (previous, current) {
                return previous.messages.length != current.messages.length;
              },
              listener: (context, state) {
                _scrollToBottom();
              },
              child: BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  return ChatMessageList(
                    messages: state.messages,
                    currentUserId: state.currentUserId,
                    scrollController: _scrollController,
                    isFetchingHistory: state.isFetchingHistory,
                    messageStatus: state.messageStatus,
                  );
                },
              ),
            ),
          ),

          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const .symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: .horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Padding(
                      padding: const .only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: .circular(8),
                            child: file.bytes != null
                                ? Image.memory(
                                    file.bytes!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade300,
                                    child: const FaIcon(FontAwesomeIcons.image),
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeFile(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const FaIcon(
                                  FontAwesomeIcons.xmark,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
            onFilesSelected: _pickFiles,
            selectedFilesCount: _selectedFiles.length,
          ),
        ],
      ),
    );
  }
}
