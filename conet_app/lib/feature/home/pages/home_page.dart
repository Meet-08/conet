import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/profile_completion_card.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_fab.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 160),
            children: const [
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Latest Posts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 12),
              PostCard(),
              PostCard(),
            ],
          ),

          // Floating create post button
          const Positioned(bottom: 110, right: 16, child: CreatePostFab()),

          // Floating profile card
          const Align(
            alignment: Alignment.bottomCenter,
            child: ProfileCompletionCard(),
          ),
        ],
      ),
    );
  }
}
