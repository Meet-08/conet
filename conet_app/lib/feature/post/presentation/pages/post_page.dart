import 'package:conet_app/core/utils/post_share_helper.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostPage extends StatelessWidget {
  final Post post;

  const PostPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            onPressed: () async {
              await PostShareHelper.sharePost(
                postId: post.id,
                username: post.user.username,
                content: post.content,
              );
            },
            icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 18),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              'By ${post.user.username}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
