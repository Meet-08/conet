import 'dart:async';

import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_posts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostGetPosts _getPosts;
  final PostCreate _createPost;
  final PostDelete _deletePost;
  final PostToggleLike _toggleLike;
  final PostComment _commentPost;
  final PostWatchPosts _watchPosts;

  StreamSubscription<List<Post>>? _postSub;

  PostBloc({
    required PostGetPosts getPosts,
    required PostCreate createPost,
    required PostDelete deletePost,
    required PostToggleLike toggleLike,
    required PostComment commentPost,
    required PostWatchPosts watchPosts,
  }) : _getPosts = getPosts,
       _createPost = createPost,
       _deletePost = deletePost,
       _toggleLike = toggleLike,
       _commentPost = commentPost,
       _watchPosts = watchPosts,
       super(PostInitial()) {
    on<PostSubscribeEvent>(_onSubscribe);
    on<PostUnsubscribeEvent>(_onUnsubscribe);
    on<PostCreatePostEvent>(_onCreatePost);
    on<PostDeletePostEvent>(_onDeletePost);
    on<PostToggleLikePostEvent>(_onToggleLike);
    on<PostCommentEvent>(_onComment);
  }

  void _onUnsubscribe(PostUnsubscribeEvent event, Emitter<PostState> emit) {
    _postSub?.cancel();
    _postSub = null;
  }

  Future<void> _onSubscribe(
    PostSubscribeEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    // Initial load
    final initial = await _getPosts();
    initial.fold(
      (failure) => emit(PostFailure(failure.message)),
      (posts) => emit(PostLoaded(posts)),
    );

    // Realtime stream
    await emit.forEach<List<Post>>(
      _watchPosts(),
      onData: (posts) => PostLoaded(posts),
      onError: (error, _) => PostFailure(error.toString()),
    );
  }

  Future<void> _onCreatePost(
    PostCreatePostEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _createPost(
      content: event.content,
      media: event.media,
    );

    result.fold((failure) => emit(PostFailure(failure.message)), (post) {
      final currentPosts = state is PostLoaded
          ? (state as PostLoaded).posts
          : <Post>[];
      emit(PostLoaded([...currentPosts, post], recentlyCreated: true));
    });
  }

  Future<void> _onDeletePost(
    PostDeletePostEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _deletePost(event.postId);

    result.fold((failure) => emit(PostFailure(failure.message)), (_) {});
  }

  Future<void> _onToggleLike(
    PostToggleLikePostEvent event,
    Emitter<PostState> emit,
  ) async {
    if (state is! PostLoaded) return;

    final current = (state as PostLoaded).posts;

    final updated = current.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
        );
      }
      return post;
    }).toList();

    emit(PostLoaded(updated));

    final result = await _toggleLike(event.postId);

    result.fold((failure) {
      // rollback if needed
      emit(PostLoaded(current));
    }, (_) {});
  }

  Future<void> _onComment(
    PostCommentEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _commentPost(event.postId, event.comment);

    result.fold((failure) => emit(PostFailure(failure.message)), (_) {});
  }

  @override
  Future<void> close() {
    _postSub?.cancel();
    return super.close();
  }
}
