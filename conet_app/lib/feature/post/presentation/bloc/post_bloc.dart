import 'dart:io';

import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
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

  PostBloc({
    required PostGetPosts getPosts,
    required PostCreate createPost,
    required PostDelete deletePost,
    required PostToggleLike toggleLike,
    required PostComment commentPost,
  }) : _getPosts = getPosts,
       _createPost = createPost,
       _deletePost = deletePost,
       _toggleLike = toggleLike,
       _commentPost = commentPost,
       super(PostInitial()) {
    on<PostGetPostsEvent>(_onGetPosts);
    on<PostCreatePostEvent>(_onCreatePost);
    on<PostDeletePostEvent>(_onDeletePost);
    on<PostToggleLikePostEvent>(_onToggleLike);
    on<PostCommentEvent>(_onComment);
  }

  Future<void> _onGetPosts(
    PostGetPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());
    final result = await _getPosts(page: event.page, limit: event.limit);
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (posts) => emit(PostLoaded(posts)),
    );
  }

  Future<void> _onCreatePost(
    PostCreatePostEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostActionInProgress());
    final result = await _createPost(
      content: event.content,
      media: event.media,
    );
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (post) => emit(PostActionSuccess()),
    );
  }

  Future<void> _onDeletePost(
    PostDeletePostEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostActionInProgress());
    final result = await _deletePost(event.postId);
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (_) => emit(PostActionSuccess()),
    );
  }

  Future<void> _onToggleLike(
    PostToggleLikePostEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _toggleLike(event.postId);
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (_) => emit(PostActionSuccess()),
    );
  }

  Future<void> _onComment(
    PostCommentEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostActionInProgress());
    final result = await _commentPost(event.postId, event.comment);
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (_) => emit(PostActionSuccess()),
    );
  }
}
