import 'dart:async';

import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/conversation_list.dart';
import 'package:conet_app/feature/message/presentation/widgets/message_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/message_filters.dart';
import 'package:conet_app/feature/message/presentation/widgets/new_message_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearchMode = false;
  String _searchQuery = '';
  late final MessageBloc _messageBloc;

  @override
  void initState() {
    super.initState();
    _messageBloc = context.read<MessageBloc>();
    _messageBloc.add(MessageConversationsRequested());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateConversationDialog() async {
    _messageBloc.add(MessageUserSearchCleared());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _messageBloc,
        child: const NewMessageSheet(),
      ),
    );
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchDebounce?.cancel();
        _searchController.clear();
        _searchQuery = '';
        _messageBloc.add(
          MessageConversationsRequested(searchQuery: ''),
        );
      }
    });
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _searchQuery = query;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _messageBloc.add(
        MessageConversationsRequested(searchQuery: query),
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _searchQuery.toLowerCase();

    return MultiBlocListener(
      listeners: [
        BlocListener<MessageBloc, MessageState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            AppToast.showError(context, state.errorMessage!);
          },
        ),
        BlocListener<MessageBloc, MessageState>(
          listenWhen: (previous, current) =>
              previous.createdConversation == null &&
              current.createdConversation != null,
          listener: (context, state) {
            final conversation = state.createdConversation!;
            _messageBloc.add(
              MessageCreatedConversationHandled(),
            );
            context.push('/chat-detail', extra: conversation);
          },
        ),
      ],
      child: Scaffold(
        appBar: MessageAppBar(
          onSearchPressed: _toggleSearchMode,
          onAddPressed: _showCreateConversationDialog,
          isSearching: _isSearchMode,
        ),
        body: Column(
          children: [
            if (_isSearchMode)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.borderSubtle,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.xmark,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                ),
              ),
            const MessageFilters(),
            Expanded(
              child: BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  if (state.conversationStatus == MessageStatus.loading &&
                      state.conversations.isEmpty) {
                    return const Center(child: Loader());
                  }

                  if (state.conversations.isEmpty) {
                    final colors = Theme.of(
                      context,
                    ).extension<AppSemanticColors>()!;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.commentDots,
                            size: 64,
                            color: colors.iconTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            normalizedQuery.isNotEmpty
                                ? 'No matching conversations'
                                : 'No conversations yet',
                            style: AppTextStyles.bodyDefault.copyWith(
                              color: colors.textSecondary,
                              fontWeight: AppTypographyTokens.weightMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            normalizedQuery.isNotEmpty
                                ? 'Try a different name or message preview'
                                : 'Tap + to start a new conversation',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ConversationList(conversations: state.conversations);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
