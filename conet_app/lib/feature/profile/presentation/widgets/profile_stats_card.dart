import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ProfileStatsCard extends StatelessWidget {
  final int followerCount;
  final int followingCount;

  const ProfileStatsCard({
    super.key,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$followingCount',
          style: AppTextStyles.bodyDefault.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Following',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textSecondary,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          '$followerCount',
          style: AppTextStyles.bodyDefault.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Followers',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textSecondary,
          ),
        ),
      ],
    );
  }
}
