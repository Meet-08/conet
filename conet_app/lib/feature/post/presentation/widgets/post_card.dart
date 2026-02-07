import 'package:conet_app/core/utils/date_formatter.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final tags = _extractTags(post.content);
    final displayedContent = _removeTags(post.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        post.user.profilePicUrl != null &&
                            post.user.profilePicUrl!.isNotEmpty
                        ? NetworkImage(post.user.profilePicUrl!)
                        : null,
                    child:
                        post.user.profilePicUrl == null ||
                            post.user.profilePicUrl!.isEmpty
                        ? Text(
                            post.user.username.isNotEmpty
                                ? post.user.username[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.user.username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          DateFormatter.format(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Content
              Text(displayedContent),

              const SizedBox(height: 8),

              // Image
              if (post.mediaUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.mediaUrls.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            post.mediaUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // Tags
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: tags.map((tag) => _TagChip(text: tag)).toList(),
                ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      context.read<PostBloc>().add(
                        PostToggleLikePostEvent(postId: post.id),
                      );
                    },
                    child: _ActionItem(
                      icon: post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: '${post.likeCount}',
                      color: post.isLiked ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ActionItem(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.commentCount}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.share_outlined),
                  const Spacer(),
                  const Icon(Icons.bookmark_border),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractTags(String content) {
    final regex = RegExp(r'\B#\w\w+');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(0)!).toList();
  }

  String _removeTags(String content) {
    return content; // decided to keep tags in body for now as removing them might break sentence context
  }
}

class _TagChip extends StatelessWidget {
  final String text;

  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
