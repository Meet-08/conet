import 'package:conet_app/feature/home/widgets/create_post_fab.dart';
import 'package:conet_app/feature/home/widgets/home_app_bar.dart';
import 'package:conet_app/feature/home/widgets/post_card.dart';
import 'package:conet_app/feature/home/widgets/profile_completion_card.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isOpen = false;

  void toggleCompletion() {
    setState(() {
      isOpen = !isOpen;
    });
  }

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
          if (isOpen)
            GestureDetector(
              onTap: toggleCompletion,
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: ProfileCompletionCard(),
              ),
            ),
        ],
      ),
    );
  }
}
