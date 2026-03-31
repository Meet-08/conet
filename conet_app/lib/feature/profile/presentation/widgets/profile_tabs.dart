import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).extension<AppSemanticColors>()!.backgroundTertiary,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: const Row(
        children: [
          Expanded(child: _TabItem(text: 'My Posts', isActive: true)),
          Expanded(child: _TabItem(text: 'Activity')),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isActive;

  const _TabItem({required this.text, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isActive
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          fontWeight: FontWeight.w600,
          color: isActive
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
        ),
      ),
    );
  }
}
