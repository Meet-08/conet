import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef GroupPermissionsSaveCallback =
    Future<void> Function({
      required bool onlyAdminsCanAddMembers,
      required bool onlyAdminsCanRemoveMembers,
      required bool onlyAdminsCanEditGroup,
      required bool onlyAdminsCanSendMessages,
    });

class GroupPermissionsDialog extends StatefulWidget {
  final bool onlyAdminsCanAddMembers;
  final bool onlyAdminsCanRemoveMembers;
  final bool onlyAdminsCanEditGroup;
  final bool onlyAdminsCanSendMessages;
  final bool canEditPermissions;
  final GroupPermissionsSaveCallback? onSave;

  const GroupPermissionsDialog({
    super.key,
    required this.onlyAdminsCanAddMembers,
    required this.onlyAdminsCanRemoveMembers,
    required this.onlyAdminsCanEditGroup,
    required this.onlyAdminsCanSendMessages,
    required this.canEditPermissions,
    this.onSave,
  });

  @override
  State<GroupPermissionsDialog> createState() => _GroupPermissionsDialogState();
}

class _GroupPermissionsDialogState extends State<GroupPermissionsDialog> {
  late bool _onlyAdminsCanAddMembers;
  late bool _onlyAdminsCanRemoveMembers;
  late bool _onlyAdminsCanEditGroup;
  late bool _onlyAdminsCanSendMessages;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _onlyAdminsCanAddMembers = widget.onlyAdminsCanAddMembers;
    _onlyAdminsCanRemoveMembers = widget.onlyAdminsCanRemoveMembers;
    _onlyAdminsCanEditGroup = widget.onlyAdminsCanEditGroup;
    _onlyAdminsCanSendMessages = widget.onlyAdminsCanSendMessages;
  }

  Future<void> _save() async {
    if (widget.onSave == null || _isSaving) {
      context.pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.onSave!(
      onlyAdminsCanAddMembers: _onlyAdminsCanAddMembers,
      onlyAdminsCanRemoveMembers: _onlyAdminsCanRemoveMembers,
      onlyAdminsCanEditGroup: _onlyAdminsCanEditGroup,
      onlyAdminsCanSendMessages: _onlyAdminsCanSendMessages,
    );

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    final canEdit = widget.canEditPermissions && !_isSaving;

    return AlertDialog(
      title: Text(
        'Group Permissions',
        style: AppTextStyles.headingH3.copyWith(color: colors.textPrimary),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PermissionToggleTile(
              title: 'Only admins can add new members',
              value: _onlyAdminsCanAddMembers,
              enabled: canEdit,
              onChanged: (value) {
                setState(() {
                  _onlyAdminsCanAddMembers = value;
                });
              },
            ),
            _PermissionToggleTile(
              title: 'Only admins can remove members',
              value: _onlyAdminsCanRemoveMembers,
              enabled: canEdit,
              onChanged: (value) {
                setState(() {
                  _onlyAdminsCanRemoveMembers = value;
                });
              },
            ),
            _PermissionToggleTile(
              title: 'Only admins can edit group name/image',
              value: _onlyAdminsCanEditGroup,
              enabled: canEdit,
              onChanged: (value) {
                setState(() {
                  _onlyAdminsCanEditGroup = value;
                });
              },
            ),
            _PermissionToggleTile(
              title: 'Only admins can send messages',
              value: _onlyAdminsCanSendMessages,
              enabled: canEdit,
              onChanged: (value) {
                setState(() {
                  _onlyAdminsCanSendMessages = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Close')),
        FilledButton(
          onPressed: canEdit ? _save : null,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _PermissionToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PermissionToggleTile({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: enabled ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
