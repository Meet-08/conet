import 'package:conet_app/feature/postcreate/widgets/add_tags_section.dart';
import 'package:conet_app/feature/postcreate/widgets/create_post_app_bar.dart';
import 'package:conet_app/feature/postcreate/widgets/popular_tags.dart';
import 'package:conet_app/feature/postcreate/widgets/post_actions_row.dart';
import 'package:conet_app/feature/postcreate/widgets/post_text_field.dart';
import 'package:flutter/material.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CreatePostAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
