import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/conversation_list.dart';
import 'package:conet_app/feature/message/presentation/widgets/message_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/message_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    final controller = TextEditingController();
    final userId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start a conversation'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    dialogContext.read<MessageBloc>().add(
                      MessageUserSearchRequested(value),
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    hintText: 'Start typing to search',
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<MessageBloc, MessageState>(
                  builder: (context, state) {
                    if (state.isSearchingUsers) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      );
                    }

                    if (state.userSearchError != null) {
                      return Text(
                        state.userSearchError!,
                        style: const TextStyle(color: Colors.redAccent),
                      );
                    }

                    if (state.userSuggestions.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.userSuggestions.length,
                      separatorBuilder: (_, _) => const Divider(height: 8),
                      itemBuilder: (context, index) {
                        final user = state.userSuggestions[index];
                        final displayName = '${user.firstName} ${user.lastName}'
                            .trim();
                        final subtitle = user.email.isNotEmpty
                            ? user.email
                            : (user.username.isNotEmpty
                                  ? '@${user.username}'
                                  : '');
                        final initials = displayName.isNotEmpty
                            ? displayName
                                  .split(RegExp(r'\s+'))
                                  .map((part) => part.isNotEmpty ? part[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                            : (user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U');

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage:
                                (user.profilePicUrl != null &&
                                    user.profilePicUrl!.isNotEmpty)
                                ? NetworkImage(user.profilePicUrl!)
                                : null,
                            child:
                                (user.profilePicUrl == null ||
                                    user.profilePicUrl!.isEmpty)
                                ? Text(initials)
                                : null,
                          ),
                          title: Text(
                            displayName.isNotEmpty
                                ? displayName
                                : (user.username.isNotEmpty
                                      ? user.username
                                      : 'User'),
                          ),
                          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                          onTap: () {
                            dialogContext.read<MessageBloc>().add(
                              MessageUserSearchCleared(),
                            );
                            Navigator.pop(dialogContext, user.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                dialogContext.read<MessageBloc>().add(
                  MessageUserSearchCleared(),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                dialogContext.read<MessageBloc>().add(
                  MessageUserSearchCleared(),
                );
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (userId != null && userId.isNotEmpty && context.mounted) {
      context.read<MessageBloc>().add(MessageConversationCreated(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessageBloc, MessageState>(
      listener: (context, state) {
        if (state.status == MessageStatus.failure &&
            state.errorMessage != null) {
          AppToast.showError(context, state.errorMessage!);
        }
      },
      child: Scaffold(
        appBar: MessageAppBar(onAddPressed: _showCreateConversationDialog),
        body: Column(
          children: [
            const MessageFilters(),
            Expanded(
              child: BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  if (state.status == MessageStatus.loading &&
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
