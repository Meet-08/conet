import 'package:conet_app/core/utils/pick_files.dart';
import 'package:file_picker/file_picker.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _contentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostBloc>().add(PostSubscribeEvent());
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createPost() {
    if (_contentController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      return;
    }

    context.read<PostBloc>().add(
      PostCreatePostEvent(
        content: _contentController.text,
        media: _selectedFiles,
      ),
    );

    _contentController.clear();
    setState(() => _selectedFiles = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          if (state is PostFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PostLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! PostLoaded) {
            return const SizedBox();
          }

          final posts = state.posts;

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<PostBloc>();
              bloc.add(PostUnsubscribeEvent());
              bloc.add(PostSubscribeEvent());
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              children: [
                _buildCreatePost(),
                const SizedBox(height: 12),
                ...posts.map(_buildPostCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreatePost() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final files = await pickFiles();
                    if (files != null) {
                      setState(() => _selectedFiles = files);
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Media"),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _createPost,
                  child: const Text("Post"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.user.profilePicUrl != null && post.user.profilePicUrl!.isNotEmpty
                      ? NetworkImage(post.user.profilePicUrl!)
                      : null,
                  radius: 20,
                  child: (post.user.profilePicUrl == null || post.user.profilePicUrl!.isEmpty)
                      ? Text(
                          post.user.username.isNotEmpty ? post.user.username[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
            ),
            Text(post.content),
            const SizedBox(height: 8),
            if (post.mediaUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.mediaUrls.length,
                  itemBuilder: (context, index) {
                    final url = post.mediaUrls[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    context.read<PostBloc>().add(
                      PostToggleLikePostEvent(postId: post.id),
                    );
                  },
                ),
                Text("${post.likeCount}"),
                const SizedBox(width: 16),
                Text("${post.commentCount} comments"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
