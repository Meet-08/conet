import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/conversation_list.dart';
import 'package:conet_app/feature/message/presentation/widgets/message_app_bar.dart';
import 'package:conet_app/feature/message/presentation/widgets/message_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                      separatorBuilder: (_, __) => const Divider(height: 8),
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
                            final selected = user.email.isNotEmpty
                                ? user.email
                                : user.username;
                            dialogContext.read<MessageBloc>().add(
                              MessageUserSearchCleared(),
                            );
                            Navigator.pop(dialogContext, selected);
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.conversations.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No conversations yet'),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${state.status.name}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ],
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
