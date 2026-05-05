import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/message/presentation/widgets/group_permissions_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class GroupDetailsPage extends StatefulWidget {
  final Conversation conversation;

  const GroupDetailsPage({super.key, required this.conversation});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  bool _showAllMembers = false;
  bool _isUploadingGroupImage = false;

  bool _canEditGroupDetails(Conversation conversation) {
    return !conversation.onlyAdminEditGroup || conversation.isAdmin;
  }

  bool _canManageGroupMembers(Conversation conversation) {
    return !conversation.onlyAdminAddMembers || conversation.isAdmin;
  }

  @override
  void initState() {
    super.initState();
    final messageBloc = context.read<MessageBloc>();
    messageBloc.add(MessageGroupMembersRequested(widget.conversation.id));
    messageBloc.add(MessageConversationsRequested());
    messageBloc.add(MessageUserSearchCleared());
  }

  Conversation _resolveConversation(MessageState state) {
    for (final conversation in state.conversations) {
      if (conversation.id == widget.conversation.id) {
        return conversation;
      }
    }
    return widget.conversation;
  }

  List<GroupMember> _resolveMembers(
    MessageState state,
    Conversation conversation,
  ) {
    final members = switch ((
      state.groupMembers,
      conversation.members,
      widget.conversation.members,
    )) {
      (final stateMembers, _, _) when stateMembers.isNotEmpty => stateMembers,
      (_, final conversationMembers, _) when conversationMembers.isNotEmpty =>
        conversationMembers,
      (_, _, final fallbackMembers) => fallbackMembers,
    };

    return members;
  }

  GroupMember? _findCreator(List<GroupMember> members, String? creatorId) {
    if (creatorId == null || creatorId.isEmpty) return null;
    for (final member in members) {
      if (member.id == creatorId) {
        return member;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _openAddMembersSheet(Conversation conversation) async {
    final addMembersTitle = conversation.isEvent
        ? 'Add Event Members'
        : 'Add Members';
    showUserSelectorBottomSheet(
      context: context,
      title: addMembersTitle,
      searchHint: 'Search by name, username, or email',
      actionLabel: 'Add to Group',
      allowMultipleSelection: false,
      onUserTap: (parentContext, user) => context.read<MessageBloc>().add(
        MessageGroupMemberAdded(groupId: conversation.id, userId: user.id),
      ),
    );
  }

  void _promoteMember(String userId) {
    context.read<MessageBloc>().add(
      MessageGroupMemberPromoted(
        groupId: widget.conversation.id,
        userId: userId,
      ),
    );
    AppToast.showSuccess(context, 'Promote request sent.');
  }

  void _demoteMember(String userId) {
    context.read<MessageBloc>().add(
      MessageGroupMemberDemoted(
        groupId: widget.conversation.id,
        userId: userId,
      ),
    );
    AppToast.showSuccess(context, 'Demote request sent.');
  }

  Future<void> _pickAndUploadGroupImage(Conversation conversation) async {
    if (!_canEditGroupDetails(conversation)) {
      AppToast.showInfo(
        context,
        'You do not have permission to update group details.',
      );
      return;
    }

    final files = await pickFiles(
      limit: 1,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );

    if (!mounted || files == null || files.isEmpty) return;

    setState(() {
      _isUploadingGroupImage = true;
    });

    context.read<MessageBloc>().add(
      MessageGroupUpdated(
        groupId: conversation.id,
        groupImageFile: files.first,
      ),
    );

    if (!mounted) return;
    setState(() {
      _isUploadingGroupImage = false;
    });
    AppToast.showSuccess(context, 'Group image update requested.');
  }

  Future<void> _openGroupPermissionsDialog({
    required Conversation conversation,
  }) {
    final canEditPermissions = _canEditGroupDetails(conversation);

    return showDialog<void>(
      context: context,
      builder: (_) => GroupPermissionsDialog(
        onlyAdminsCanAddMembers: conversation.onlyAdminAddMembers,
        onlyAdminsCanRemoveMembers: conversation.onlyAdminRemoveMembers,
        onlyAdminsCanEditGroup: conversation.onlyAdminEditGroup,
        onlyAdminsCanSendMessages: conversation.onlyAdminSendMessages,
        canEditPermissions: canEditPermissions,
        onSave:
            ({
              required onlyAdminsCanAddMembers,
              required onlyAdminsCanRemoveMembers,
              required onlyAdminsCanEditGroup,
              required onlyAdminsCanSendMessages,
            }) async {
              if (!canEditPermissions) return;
              context.read<MessageBloc>().add(
                MessageGroupUpdated(
                  groupId: conversation.id,
                  onlyAdminAddMembers: onlyAdminsCanAddMembers,
                  onlyAdminRemoveMembers: onlyAdminsCanRemoveMembers,
                  onlyAdminEditGroup: onlyAdminsCanEditGroup,
                  onlyAdminSendMessages: onlyAdminsCanSendMessages,
                ),
              );
              AppToast.showSuccess(
                context,
                'Group permissions update requested.',
              );
            },
      ),
    );
  }

  Future<void> _openEditDescriptionDialog(Conversation conversation) async {
    if (!_canEditGroupDetails(conversation)) {
      AppToast.showInfo(
        context,
        'You do not have permission to update group details.',
      );
      return;
    }

    final controller = TextEditingController(
      text: conversation.description ?? '',
    );

    final newDescription = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Group Description'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 400,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Tell members what this group is about',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || newDescription == null) {
      return;
    }

    context.read<MessageBloc>().add(
      MessageGroupUpdated(
        groupId: conversation.id,
        description: newDescription,
      ),
    );
    AppToast.showSuccess(context, 'Group description update requested.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return BlocListener<MessageBloc, MessageState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        AppToast.showError(context, state.errorMessage!);
      },
      child: Scaffold(
        backgroundColor: colors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: colors.backgroundSecondary,
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
              onPressed: () {
                AppToast.showInfo(context, 'More actions will be added soon.');
              },
            ),
          ],
        ),
        body: BlocBuilder<MessageBloc, MessageState>(
          builder: (context, state) {
            final conversation = _resolveConversation(state);
            final members = _resolveMembers(state, conversation);
            final creator = _findCreator(members, conversation.createdBy);
            final visibleMembers = _showAllMembers
                ? members
                : members.take(5).toList();
            final canManageMembers = _canManageGroupMembers(conversation);
            final canManageMemberRoles = conversation.isAdmin;
            final currentUserId = state.currentUserId;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        _GroupAvatar(
                          conversation: conversation,
                          isUpdating: _isUploadingGroupImage,
                          onTap: () => _pickAndUploadGroupImage(conversation),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          conversation.displayName,
                          style: AppTextStyles.headingH3.copyWith(
                            color: colors.textPrimary,
                            fontWeight: AppTypographyTokens.weightBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conversation.isEvent
                              ? '${members.length} Event Members'
                              : '${members.length} Members',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Group Description',
                        style: AppTextStyles.label.copyWith(
                          color: colors.textPrimary,
                          fontWeight: AppTypographyTokens.weightBold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Edit description',
                        onPressed: () =>
                            _openEditDescriptionDialog(conversation),
                        icon: FaIcon(
                          FontAwesomeIcons.penToSquare,
                          size: 14,
                          color: _canEditGroupDetails(conversation)
                              ? colors.iconSecondary
                              : colors.iconDisabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conversation.description?.trim().isNotEmpty == true
                        ? conversation.description!.trim()
                        : 'No group description yet.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        conversation.isEvent
                            ? '${members.length} Event Members'
                            : '${members.length} Members',
                        style: AppTextStyles.headingH3.copyWith(
                          color: colors.textPrimary,
                          fontWeight: AppTypographyTokens.weightBold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllMembers = !_showAllMembers;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAllMembers ? 'view less' : 'view all',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            FaIcon(
                              _showAllMembers
                                  ? FontAwesomeIcons.chevronUp
                                  : FontAwesomeIcons.chevronRight,
                              size: 10,
                              color: colors.iconSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canManageMembers
                        ? () => _openAddMembersSheet(conversation)
                        : () => AppToast.showInfo(
                            context,
                            'You do not have permission to add members.',
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: colors.backgroundWarning,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.plus,
                                size: 14,
                                color: colors.iconPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            conversation.isEvent
                                ? 'Add Event Members'
                                : 'Add Members',
                            style: AppTextStyles.bodyDefault.copyWith(
                              color: canManageMembers
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontWeight: AppTypographyTokens.weightMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...visibleMembers.map(
                    (member) => _MemberTile(
                      member: member,
                      showAdminBadge: member.role.toLowerCase() == 'admin',
                      canManageRoles: canManageMemberRoles,
                      isSelf:
                          currentUserId != null && member.id == currentUserId,
                      onPromote: () => _promoteMember(member.id),
                      onDemote: () => _demoteMember(member.id),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GroupSettingTile(
                    title: 'Shared media, links and docs',
                    onTap: () {
                      AppToast.showInfo(
                        context,
                        'Shared media section is not available yet.',
                      );
                    },
                  ),
                  _GroupSettingTile(
                    title: 'Group Permissions',
                    onTap: () =>
                        _openGroupPermissionsDialog(conversation: conversation),
                  ),
                  _GroupSettingTile(
                    title: 'Notification',
                    onTap: () {
                      AppToast.showInfo(
                        context,
                        'Notification settings are not available yet.',
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    creator == null
                        ? 'Group creator details are unavailable from backend.'
                        : creator.joinedAt == null
                        ? 'Group created by ${creator.displayName}'
                        : 'Group created by ${creator.displayName} on ${_formatDate(creator.joinedAt!)}',
                    style: AppTextStyles.micro.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final bool isUpdating;

  const _GroupAvatar({
    required this.conversation,
    required this.onTap,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: isUpdating ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomCircleAvatar(
            radius: 40,
            imageUrl: conversation.groupImageUrl,
            displayName: conversation.displayName,
            backgroundColor: colors.backgroundTertiary,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.backgroundInverse,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surfaceBase, width: 2),
              ),
              child: Center(
                child: isUpdating
                    ? SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.iconInverse,
                          ),
                        ),
                      )
                    : FaIcon(
                        FontAwesomeIcons.camera,
                        size: 10,
                        color: colors.iconInverse,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool showAdminBadge;
  final bool canManageRoles;
  final bool isSelf;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;

  const _MemberTile({
    required this.member,
    required this.showAdminBadge,
    required this.canManageRoles,
    required this.isSelf,
    this.onPromote,
    this.onDemote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CustomCircleAvatar(
            size: CustomCircleAvatarSize.medium,
            imageUrl: member.profilePicUrl,
            displayName: member.displayName,
            userId: member.id,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: AppTextStyles.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: AppTypographyTokens.weightMedium,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '@${member.username}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showAdminBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.backgroundWarning,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Group admin',
                style: AppTextStyles.micro.copyWith(
                  color: colors.textPrimary,
                  fontWeight: AppTypographyTokens.weightMedium,
                ),
              ),
            ),
          if (canManageRoles && !isSelf)
            PopupMenuButton<String>(
              icon: FaIcon(
                FontAwesomeIcons.ellipsisVertical,
                size: 14,
                color: colors.iconSecondary,
              ),
              onSelected: (action) {
                if (action == 'promote') {
                  onPromote?.call();
                } else if (action == 'demote') {
                  onDemote?.call();
                }
              },
              itemBuilder: (context) => member.isAdmin
                  ? [
                      PopupMenuItem<String>(
                        value: 'demote',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.userMinus,
                              size: 14,
                              color: colors.iconSecondary,
                            ),
                            const SizedBox(width: 10),
                            const Text('Demote to member'),
                          ],
                        ),
                      ),
                    ]
                  : [
                      PopupMenuItem<String>(
                        value: 'promote',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.userPlus,
                              size: 14,
                              color: colors.iconSecondary,
                            ),
                            const SizedBox(width: 10),
                            const Text('Promote to admin'),
                          ],
                        ),
                      ),
                    ],
            ),
        ],
      ),
    );
  }
}

class _GroupSettingTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool enabled;

  const _GroupSettingTile({
    required this.title,
    required this.onTap,
    // ignore: unused_element_parameter
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyDefault.copyWith(
                    color: enabled ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
              ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 14,
                color: enabled ? colors.iconTertiary : colors.iconDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGroupMemberSheet extends StatefulWidget {
  final String groupId;
  final Set<String> existingMemberIds;

  const _AddGroupMemberSheet({
    required this.groupId,
    required this.existingMemberIds,
  });

  @override
  State<_AddGroupMemberSheet> createState() => _AddGroupMemberSheetState();
}

class _AddGroupMemberSheetState extends State<_AddGroupMemberSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: colors.surfaceBase,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Members',
              style: AppTextStyles.headingH3.copyWith(
                color: colors.textPrimary,
                fontWeight: AppTypographyTokens.weightBold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or username',
                prefixIcon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
                filled: true,
                fillColor: colors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<MessageBloc>().add(
                  MessageUserSearchRequested(value),
                );
              },
            ),
            const SizedBox(height: 10),
            BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                final suggestions = state.userSuggestions
                    .where(
                      (user) => !widget.existingMemberIds.contains(user.id),
                    )
                    .toList();

                if (state.isSearchingUsers) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_searchController.text.trim().isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Type to search people and add them to this group.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }

                if (suggestions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No matching users found.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 260,
                  child: ListView.separated(
                    itemCount: suggestions.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: colors.borderSubtle),
                    itemBuilder: (context, index) {
                      final user = suggestions[index];
                      final fullName = '${user.firstName} ${user.lastName}'
                          .trim();
                      final displayName = fullName.isEmpty
                          ? user.username
                          : fullName;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CustomCircleAvatar(
                          size: CustomCircleAvatarSize.medium,
                          imageUrl: user.profilePicUrl,
                          displayName: displayName,
                        ),
                        title: Text(
                          displayName,
                          style: AppTextStyles.bodyDefault.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '@${user.username}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            context.read<MessageBloc>().add(
                              MessageGroupMemberAdded(
                                groupId: widget.groupId,
                                userId: user.id,
                              ),
                            );
                            Navigator.pop(context);
                            AppToast.showSuccess(
                              context,
                              'Member add request sent.',
                            );
                          },
                          child: const Text('Add'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
