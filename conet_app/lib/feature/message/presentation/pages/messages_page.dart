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
  @override
  void initState() {
    super.initState();
    context.read<MessageBloc>().add(MessageConversationsRequested());
  }

  Future<void> _showCreateConversationDialog() async {
    context.read<MessageBloc>().add(MessageUserSearchCleared());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MessageBloc>(),
        child: const NewMessageSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            context.read<MessageBloc>().add(
              MessageCreatedConversationHandled(),
            );
            context.push('/chat-detail', extra: conversation);
          },
        ),
      ],
      child: Scaffold(
        appBar: MessageAppBar(onAddPressed: _showCreateConversationDialog),
        body: Column(
          children: [
            const MessageFilters(),
            Expanded(
              child: BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  if (state.conversationStatus == MessageStatus.loading &&
                      state.conversations.isEmpty) {
                    return const Center(child: Loader());
                  }

                  if (state.conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.commentDots,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to start a new conversation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
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
