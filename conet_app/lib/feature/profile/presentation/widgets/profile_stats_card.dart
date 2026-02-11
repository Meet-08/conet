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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          'Following',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 20),
        Text(
          '$followerCount',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          'Followers',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
