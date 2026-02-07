import 'package:flutter/material.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/interests_section.dart';
import '../widgets/social_links_section.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/profile_tabs.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
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
