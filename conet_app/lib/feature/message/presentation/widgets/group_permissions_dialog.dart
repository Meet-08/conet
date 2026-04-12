import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class GroupPermissionsDialog extends StatelessWidget {
  final bool canManageMembers;
  final bool canEditGroup;
  final bool canDeleteGroup;

  const GroupPermissionsDialog({
    super.key,
    required this.canManageMembers,
    required this.canEditGroup,
    required this.canDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

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
              value: canManageMembers,
            ),
            _PermissionToggleTile(
              title: 'Only admins can remove members',
              value: canManageMembers,
            ),
            _PermissionToggleTile(
              title: 'Only admins can edit group name/image',
              value: canEditGroup,
            ),
            _PermissionToggleTile(
              title: 'Only creator can delete the group',
              value: canDeleteGroup,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PermissionToggleTile extends StatelessWidget {
  final String title;
  final bool value;

  const _PermissionToggleTile({required this.title, required this.value});

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
                color: colors.textPrimary,
              ),
            ),
          ),
          Switch(value: value, onChanged: null),
        ],
      ),
    );
  }
}
