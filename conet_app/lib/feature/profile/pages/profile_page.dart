import 'package:conet_app/feature/profile/widgets/interests_section.dart';
import 'package:conet_app/feature/profile/widgets/profile_app_bar.dart';
import 'package:conet_app/feature/profile/widgets/profile_header_card.dart';
import 'package:conet_app/feature/profile/widgets/profile_stats_card.dart';
import 'package:conet_app/feature/profile/widgets/profile_tabs.dart';
import 'package:conet_app/feature/profile/widgets/social_links_section.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ProfileAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileTabs(),
            SizedBox(height: 12),
            ProfileHeaderCard(),
            SizedBox(height: 16),
            InterestsSection(),
            SizedBox(height: 16),
            SocialLinksSection(),
            SizedBox(height: 16),
            ProfileStatsCard(),
          ],
        ),
      ),
    );
  }
}
