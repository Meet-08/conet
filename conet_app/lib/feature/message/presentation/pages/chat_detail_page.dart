import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/media_type_utils.dart';
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
    final files = await pickFiles(
      allowedExtensions: [
        // Images
        'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
        // Videos
        'mp4', 'mov', 'mkv', 'webm', 'avi', '3gp', 'mpeg', 'mpg',
        // Audio
        'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac',
        // Documents
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv',
      ],
    );
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

  Widget _buildFilePreviewWidget(PlatformFile file, AppSemanticColors colors) {
    final fileName = file.name;
    final mediaType = getMediaTypeFromFileName(fileName);

    // Only show image preview for actual images
    if (mediaType == MediaType.image && file.bytes != null) {
      return Image.memory(
        file.bytes!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }

    // Show appropriate icon for non-image media types
    final icon = switch (mediaType) {
      MediaType.video => FontAwesomeIcons.play,
      MediaType.audio => FontAwesomeIcons.music,
      MediaType.document => FontAwesomeIcons.fileLines,
      MediaType.image => FontAwesomeIcons.image,
      MediaType.unknown => FontAwesomeIcons.file,
    };

    return Container(
      width: 80,
      height: 80,
      color: colors.backgroundTertiary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 24, color: colors.iconSecondary),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              fileName.split('.').last.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
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
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

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
                    isGroupConversation: widget.conversation.isGroup,
                    isDirectConversation: widget.conversation.isDirect,
                    groupMembers: widget.conversation.members,
                    scrollController: _scrollController,
                    isFetchingHistory: state.isFetchingHistory,
                    messageStatus: state.messageStatus,
                    emptyMessage: 'No messages yet',
                  );
                },
              ),
            ),
          ),

          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.backgroundSecondary,
                border: Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildFilePreviewWidget(file, colors),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeFile(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.backgroundInverse.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: FaIcon(
                                  FontAwesomeIcons.xmark,
                                  color: colors.textInverse,
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
