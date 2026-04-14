import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_cohost_management_cubit.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventCohostManagementPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventCohostManagementPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventCohostManagementPage> createState() =>
      _EventCohostManagementPageState();
}

class _EventCohostManagementPageState extends State<EventCohostManagementPage> {
  bool _isCheckingAccess = true;
  bool _canManage = false;

  bool _hasOrganizerRole(String userId, Event event) {
    final normalizedUserId = userId.trim();
    if (event.organizerId.trim() == normalizedUserId) return true;

    return event.cohosts.any(
      (cohost) =>
          cohost.userId.trim() == normalizedUserId &&
          cohost.role.trim().toLowerCase() == 'organizer',
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveManageAccess();
    });
  }

  Future<void> _resolveManageAccess() async {
    final userState = context.read<AppUserCubit>().state;
    final currentUserId = userState is AppUserAuthenticated
        ? userState.user.id.trim()
        : '';

    if (currentUserId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _canManage = false;
        _isCheckingAccess = false;
      });
      return;
    }

    final result = await serviceLocator<EventGetById>()(widget.eventId);
    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _canManage = false;
          _isCheckingAccess = false;
        });
      },
      (event) {
        setState(() {
          _canManage = _hasOrganizerRole(currentUserId, event);
          _isCheckingAccess = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<EventCohostManagementCubit>()
            ..loadCohosts(widget.eventId),
      child: _EventCohostManagementView(
        eventId: widget.eventId,
        eventTitle: widget.eventTitle,
        canManage: _canManage,
        isCheckingAccess: _isCheckingAccess,
      ),
    );
  }
}

class _EventCohostManagementView extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final bool canManage;
  final bool isCheckingAccess;

  const _EventCohostManagementView({
    required this.eventId,
    required this.eventTitle,
    required this.canManage,
    required this.isCheckingAccess,
  });

  Future<void> _openAddSheet(
    BuildContext context,
    List<EventCohost> cohosts,
  ) async {
    final currentUserState = context.read<AppUserCubit>().state;
    final currentUserId = currentUserState is AppUserAuthenticated
        ? currentUserState.user.id
        : null;
    final existingIds = cohosts.map((cohost) => cohost.userId).toSet();
    final searchUsers = serviceLocator<MessageSearchUsers>();

    final selectedUsers = await showUserSelectorBottomSheet(
      context: context,
      title: 'Add Co-hosts',
      searchHint: 'Search users to add as co-host',
      emptyMessage: 'Search by name or username',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Add',
      excludedUserId: currentUserId,
      initialSelectedUsers: const [],
      searchUsers: (query, limit) async {
        final result = await searchUsers(query: query, limit: limit);
        return result.fold((failure) => throw Exception(failure.message), (
          users,
        ) {
          return users
              .where((user) => !existingIds.contains(user.id))
              .toList(growable: false);
        });
      },
    );

    if (selectedUsers == null || selectedUsers.isEmpty || !context.mounted) {
      return;
    }

    context.read<EventCohostManagementCubit>().addCohosts(
      eventId,
      selectedUsers,
    );
  }

  String _displayName(EventCohost cohost) {
    final name = cohost.displayName.trim();
    if (name.isNotEmpty) return name;
    return cohost.username.isNotEmpty ? cohost.username : 'Co-host';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<EventCohostManagementCubit, EventCohostManagementState>(
      listenWhen: (previous, current) =>
          previous.feedbackMessage != current.feedbackMessage &&
          current.feedbackMessage != null,
      listener: (context, state) {
        if (state.feedbackMessage == null) return;
        if (state.feedbackIsError) {
          AppToast.showError(context, state.feedbackMessage!);
        } else {
          AppToast.showSuccess(context, state.feedbackMessage!);
        }
        context.read<EventCohostManagementCubit>().clearFeedback();
      },
      builder: (context, state) {
        final cohosts = state.cohosts;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              eventTitle.isNotEmpty ? eventTitle : 'Co-hosts',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await context.read<EventCohostManagementCubit>().loadCohosts(
                eventId,
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.userGroup, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage co-hosts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              canManage
                                  ? 'Add or remove the people who can help run this event.'
                                  : 'Only the organizer can add or remove co-hosts.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Current co-hosts',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed:
                          state.isMutating || !canManage || isCheckingAccess
                          ? null
                          : () => _openAddSheet(context, cohosts),
                      icon: state.isMutating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const FaIcon(FontAwesomeIcons.userPlus, size: 14),
                      label: const Text('Add co-host'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.isLoading && cohosts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Loader()),
                  )
                else if (cohosts.isEmpty)
                  _EmptyCohostState(
                    isMutating:
                        state.isMutating || !canManage || isCheckingAccess,
                    onAdd: () => _openAddSheet(context, cohosts),
                  )
                else
                  ...cohosts.map(
                    (cohost) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CohostTile(
                        cohost: cohost,
                        enabled:
                            !state.isMutating && canManage && !isCheckingAccess,
                        onPromote: () => context
                            .read<EventCohostManagementCubit>()
                            .promoteCohost(eventId, cohost),
                        onRemove: () => context
                            .read<EventCohostManagementCubit>()
                            .removeCohost(eventId, cohost),
                        displayName: _displayName(cohost),
                      ),
                    ),
                  ),
                if (state.isMutating && cohosts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Updating co-hosts...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CohostTile extends StatelessWidget {
  final EventCohost cohost;
  final String displayName;
  final bool enabled;
  final VoidCallback onPromote;
  final VoidCallback onRemove;

  const _CohostTile({
    required this.cohost,
    required this.displayName,
    required this.enabled,
    required this.onPromote,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CustomCircleAvatar(
            size: CustomCircleAvatarSize.medium,
            imageUrl: cohost.profilePicUrl,
            displayName: displayName,
            userId: cohost.userId,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cohost.username.isNotEmpty
                      ? '@${cohost.username}'
                      : cohost.userId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cohost.role.trim().toLowerCase() == 'organizer'
                      ? 'Organizer'
                      : 'Co-host',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed:
                enabled && cohost.role.trim().toLowerCase() != 'organizer'
                ? onPromote
                : null,
            icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
            label: const Text('Promote'),
          ),
          IconButton(
            onPressed: enabled ? onRemove : null,
            icon: FaIcon(
              FontAwesomeIcons.trashCan,
              size: 16,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCohostState extends StatelessWidget {
  final bool isMutating;
  final VoidCallback onAdd;

  const _EmptyCohostState({required this.isMutating, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.userGroup,
            size: 30,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'No co-hosts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add people who should help manage attendance and event setup.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isMutating ? null : onAdd,
            icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
            label: const Text('Add co-host'),
          ),
        ],
      ),
    );
  }
}
