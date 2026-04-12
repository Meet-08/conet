import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/create_group_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class NewMessageSheet extends StatefulWidget {
  const NewMessageSheet({super.key});

  @override
  State<NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<NewMessageSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onUserTap(User user) {
    Navigator.of(context).pop();
    context.read<MessageBloc>().add(MessageConversationCreated(user.id));
  }

  void _openCreateGroupSheet() {
    Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MessageBloc>(),
        child: const CreateGroupSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New Message',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) {
                    context.read<MessageBloc>().add(
                      MessageUserSearchRequested(value),
                    );
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    hintText: 'Search people, groups, communities...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Static options
              _SheetOption(
                icon: FontAwesomeIcons.userGroup,
                label: 'Create Group',
                subtitle: 'Start a group conversation',
                onTap: _openCreateGroupSheet,
              ),
              _SheetOption(
                icon: FontAwesomeIcons.building,
                label: 'Create Community',
                subtitle: 'Build a community space',
                onTap: () {
                  // TODO: implement community creation
                  context.pop();
                },
              ),

              // Divider when there are suggestions
              BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  if (state.userSuggestions.isNotEmpty ||
                      state.isSearchingUsers) {
                    return const Divider(height: 1);
                  }
                  return const SizedBox.shrink();
                },
              ),

              // User search results / loading
              Expanded(
                child: BlocBuilder<MessageBloc, MessageState>(
                  builder: (context, state) {
                    if (state.isSearchingUsers) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    if (state.userSearchError != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.userSearchError!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    if (state.userSuggestions.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: state.userSuggestions.length,
                      itemBuilder: (context, index) {
                        final user = state.userSuggestions[index];
                        return _UserTile(
                          user: user,
                          onTap: () => _onUserTap(user),
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

// ---------------------------------------------------------------------------

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
        child: FaIcon(icon, size: 18, color: colorScheme.onSurface),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName = '${user.firstName} ${user.lastName}'.trim();
    final subtitle = user.email.isNotEmpty
        ? user.email
        : (user.username.isNotEmpty ? '@${user.username}' : '');
    final initials = _initials(displayName, user.username);

    return ListTile(
      leading: CustomCircleAvatar(
        size: CustomCircleAvatarSize.medium,
        imageUrl: user.profilePicUrl,
        displayName: initials,
        userId: user.id,
      ),
      title: Text(
        displayName.isNotEmpty
            ? displayName
            : (user.username.isNotEmpty ? user.username : 'User'),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      onTap: onTap,
    );
  }

  String _initials(String displayName, String username) {
    if (displayName.isNotEmpty) {
      return displayName
          .split(RegExp(r'\s+'))
          .map((p) => p.isNotEmpty ? p[0] : '')
          .take(2)
          .join()
          .toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }
}
