import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationList extends StatefulWidget {
  final List<Conversation> conversations;

  const ConversationList({super.key, required this.conversations});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detect when user scrolls to top and trigger refresh
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent &&
        _scrollController.position.extentAfter > 0) {
      context.read<MessageBloc>().add(MessageConversationsRequested());
    }
  }

  Future<void> _onRefresh() async {
    // Trigger refetch when user pulls to refresh
    context.read<MessageBloc>().add(MessageConversationsRequested());

    // Wait for the state to update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: widget.conversations.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 0.5,
          indent: 70,
          color: colors.borderSubtle,
        ),
        itemBuilder: (context, index) {
          final conversation = widget.conversations[index];
          return ConversationTile(conversation: conversation);
        },
      ),
    );
  }
}
