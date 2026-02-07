import 'package:flutter/material.dart';
import '../widgets/explore_app_bar.dart';
import '../widgets/explore_post_card.dart';
import '../widgets/trending_topics.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ExploreAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: const [
          ExplorePostCard(),
          TrendingTopics(),
          ExplorePostCard(),
        ],
      ),
    );
  }
}
