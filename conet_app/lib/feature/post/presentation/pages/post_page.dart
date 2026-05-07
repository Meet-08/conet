import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/post_share_helper.dart';
import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:conet_app/core/widgets/quill_read_only_view.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostPage extends StatelessWidget {
  final Post post;

  const PostPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            onPressed: () async {
              await PostShareHelper.sharePost(
                postId: post.id,
                username: post.user.username,
                content: quillPlainTextFromString(post.content),
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
            Text(
              'Post content',
              style: textTheme.labelMedium?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            QuillReadOnlyView(deltaJson: post.content),
            const SizedBox(height: 16),
            Text(
              'By ${post.user.username}',
              style: textTheme.labelMedium?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
