import 'package:flutter/material.dart';
import '../widgets/create_post_app_bar.dart';
import '../widgets/post_text_field.dart';
import '../widgets/post_actions_row.dart';
import '../widgets/add_tags_section.dart';
import '../widgets/popular_tags.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            PostTextField(),
            SizedBox(height: 12),
            PostActionsRow(),
            SizedBox(height: 20),
            AddTagsSection(),
            SizedBox(height: 12),
            PopularTags(),
          ],
        ),
      ),
    );
  }
}
