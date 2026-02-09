import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_fab.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_app_bar.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostBloc>().add(const PostGetPostsEvent(page: 1, limit: 20));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PostAppBar(),
      floatingActionButton: const CreatePostFab(),
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
              context.read<PostBloc>().add(
                const PostGetPostsEvent(page: 1, limit: 20),
              );
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              children: [
                const SizedBox(height: 12),
                ...posts.map((post) => PostCard(post: post)),
              ],
            ),
          );
        },
      ),
    );
  }
}
