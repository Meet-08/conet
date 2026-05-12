import 'dart:async';

import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_input_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/chat_message_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ChatDetailPage extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const Duration _watchRestartDebounce = Duration(milliseconds: 1000);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<PlatformFile> _selectedFiles = [];

  // Renamed from `messages` to avoid confusion with BlocBuilder's state.messages
  List<Message> _selectedMessages = [];

  late MessageBloc _messageBloc;
  DateTime? _lastWatchRestart;

  bool get _isSelectionMode => _selectedMessages.isNotEmpty;

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

  void _onMessageLongPress(Message message) {
    setState(() {
      if (_selectedMessages.any((m) => m.id == message.id)) {
        _selectedMessages.removeWhere((m) => m.id == message.id);
      } else {
        _selectedMessages.add(message);
      }
    });
  }

  void _onMessageTap(Message message) {
    if (!_isSelectionMode) return;
    _onMessageLongPress(message);
  }

  void _clearSelection() {
    setState(() {
      _selectedMessages = [];
    });
  }

  void _copySelectedMessages() {
    final text = _selectedMessages.map((m) => m.content).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    AppToast.showSuccess(
      context,
      'Copied ${_selectedMessages.length} message(s) to clipboard',
    );
    _clearSelection();
  }

  void _shareSelectedMessages() {
    if (!_isSelectionMode) return;

    _openForwardSheet();
  }

  Future<void> _openForwardSheet() async {
    final messageBloc = context.read<MessageBloc>();
    final previousSearchQuery = messageBloc.state.conversationSearchQuery;

    final targetConversation = await showModalBottomSheet<Conversation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: messageBloc,
        child: _ConversationForwardSheet(
          currentConversationId: widget.conversation.id,
          initialSearchQuery: previousSearchQuery,
        ),
      ),
    );

    if (!mounted) return;

    _restoreConversationSearch(previousSearchQuery);

    if (targetConversation == null) {
      // User cancelled forward — clear selection and return.
      if (_isSelectionMode) _clearSelection();
      return;
    }

    // Forward selected messages, then clear selection and navigate.
    _forwardSelectedMessages(targetConversation.id);
    if (_isSelectionMode) _clearSelection();
    context.push('/chat-detail', extra: targetConversation);
  }

  void _restoreConversationSearch(String? previousSearchQuery) {
    final normalizedPreviousQuery = previousSearchQuery?.trim();
    context.read<MessageBloc>().add(
      MessageConversationsRequested(
        searchQuery:
            normalizedPreviousQuery == null || normalizedPreviousQuery.isEmpty
            ? ''
            : normalizedPreviousQuery,
      ),
    );
  }

  void _forwardSelectedMessages(String conversationId) {
    for (final message in _selectedMessages) {
      if ((message.content?.trim().isEmpty ?? true) &&
          message.mediaUrls.isEmpty) {
        continue;
      }

      _messageBloc.add(
        MessageSent(
          conversationId: conversationId,
          content: message.content,
          mediaUrls: message.mediaUrls.isEmpty ? null : message.mediaUrls,
        ),
      );
    }
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
    setState(() => _selectedFiles = []);
  }

  Future<void> _pickFiles() async {
    final files = await pickFiles(
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'mp4',
        'mov',
        'mkv',
        'webm',
        'avi',
        '3gp',
        'mpeg',
        'mpg',
        'mp3',
        'm4a',
        'aac',
        'wav',
        'ogg',
        'flac',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'csv',
      ],
    );
    if (files != null) {
      setState(() => _selectedFiles = files);
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Widget _buildFilePreviewWidget(PlatformFile file, AppSemanticColors colors) {
    final fileName = file.name;
    final mediaType = getMediaTypeFromFileName(fileName);

    if (mediaType == MediaType.image && file.bytes != null) {
      return Image.memory(
        file.bytes!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }

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
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return ChatAppBar(conversation: widget.conversation);
  }

  PreferredSizeWidget _buildSelectionAppBar(AppSemanticColors colors) {
    return AppBar(
      backgroundColor: colors.backgroundSecondary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _clearSelection,
        tooltip: 'Cancel selection',
      ),
      title: Text(
        '${_selectedMessages.length} selected',
        style: AppTextStyles.bodyDefault.copyWith(color: colors.textPrimary),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.copy),
          tooltip: 'Copy',
          onPressed: _copySelectedMessages,
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.shareFromSquare),
          tooltip: 'Forward',
          onPressed: _shareSelectedMessages,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    // If this route is now current again (returned to via pop), ensure
    // the bloc is watching this conversation. Schedule after build to
    // avoid mutating state during build. Debounce to prevent rapid repeated
    // restarts on quick push/pop navigation.
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrentRoute &&
        _messageBloc.state.activeConversationId != widget.conversation.id) {
      final now = DateTime.now();
      final lastRestart = _lastWatchRestart;
      final canRestart =
          lastRestart == null ||
          now.difference(lastRestart) >= _watchRestartDebounce;

      if (canRestart) {
        _lastWatchRestart = now;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _messageBloc.add(MessageWatchStarted(widget.conversation.id));
        });
      }
    }

    return PopScope(
      // Pressing system back clears selection instead of popping the route
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) _clearSelection();
      },
      child: Scaffold(
        appBar: _isSelectionMode
            ? _buildSelectionAppBar(colors)
            : _buildNormalAppBar(),
        body: Column(
          children: [
            Expanded(
              child: BlocListener<MessageBloc, MessageState>(
                // Only scroll to bottom on initial message fetch (transition to success),
                // not on subsequent history fetches or updates.
                listenWhen: (previous, current) =>
                    previous.messageStatus != MessageStatus.success &&
                    current.messageStatus == MessageStatus.success &&
                    current.messages.isNotEmpty,
                listener: (context, state) => _scrollToBottom(),
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
                      onMessageLongPress: _onMessageLongPress,
                      onMessageTap: _onMessageTap,
                      selectedMessageIds: _selectedMessages
                          .map((m) => m.id)
                          .toSet(),
                    );
                  },
                ),
              ),
            ),

            if (_selectedFiles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
              enabled:
                  !widget.conversation.isGroup ||
                  !widget.conversation.onlyAdminSendMessages ||
                  widget.conversation.isAdmin,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationForwardSheet extends StatefulWidget {
  final String currentConversationId;
  final String? initialSearchQuery;

  const _ConversationForwardSheet({
    required this.currentConversationId,
    this.initialSearchQuery,
  });

  @override
  State<_ConversationForwardSheet> createState() =>
      _ConversationForwardSheetState();
}

class _ConversationForwardSheetState extends State<_ConversationForwardSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery?.trim() ?? '';
    _searchController.text = _searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MessageBloc>().add(
        MessageConversationsRequested(
          searchQuery: _searchQuery.isEmpty ? '' : _searchQuery,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _searchQuery = query;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<MessageBloc>().add(
        MessageConversationsRequested(searchQuery: query),
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _selectConversation(Conversation conversation) {
    Navigator.of(context).pop(conversation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = theme.extension<AppSemanticColors>()!;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Forward to conversation',
                        style: AppTextStyles.headingH3.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.xmark,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<MessageBloc, MessageState>(
                  builder: (context, state) {
                    final conversations = state.conversations
                        .where(
                          (conversation) =>
                              conversation.id != widget.currentConversationId,
                        )
                        .toList();

                    if (state.conversationStatus == MessageStatus.loading &&
                        conversations.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    if (conversations.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No conversations available'
                                : 'No matching conversations found',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: colors.borderSubtle),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return ListTile(
                          onTap: () => _selectConversation(conversation),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CustomCircleAvatar(
                            radius: 22,
                            imageUrl: conversation.displayImageUrl,
                            displayName: conversation.displayName,
                            backgroundColor: Colors
                                .primaries[conversation.displayName.hashCode %
                                    Colors.primaries.length]
                                .shade100,
                          ),
                          title: Text(
                            conversation.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyDefault.copyWith(
                              color: colors.textPrimary,
                              fontWeight: AppTypographyTokens.weightSemibold,
                            ),
                          ),
                          subtitle: Text(
                            conversation.lastMessage?.isNotEmpty == true
                                ? conversation.lastMessage!
                                : conversation.lastMessageMediaUrls.isNotEmpty
                                ? '${conversation.lastMessageMediaUrls.length} media item(s)'
                                : 'Tap to forward here',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
