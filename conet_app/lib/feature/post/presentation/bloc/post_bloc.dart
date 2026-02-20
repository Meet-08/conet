import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_user_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostGetPosts _getPosts;
  final PostGetUserPosts _getUserPosts;
  final PostCreate _createPost;
  final PostDelete _deletePost;
  final PostToggleLike _toggleLike;
  final PostComment _commentPost;
  final PostGetPostComments _getPostComments;

  PostBloc({
    required PostGetPosts getPosts,
    required PostGetUserPosts getUserPosts,
    required PostCreate createPost,
    required PostDelete deletePost,
    required PostToggleLike toggleLike,
    required PostComment commentPost,
    required PostGetPostComments getPostComments,
  }) : _getPosts = getPosts,
       _getUserPosts = getUserPosts,
       _createPost = createPost,
       _deletePost = deletePost,
       _toggleLike = toggleLike,
       _commentPost = commentPost,
       _getPostComments = getPostComments,
       super(PostInitial()) {
    on<PostGetPostsEvent>(_onGetPosts);
    on<PostGetUserPostsEvent>(_onGetUserPosts);
    on<PostCreatePostEvent>(_onCreatePost);
    on<PostDeletePostEvent>(_onDeletePost);
    on<PostToggleLikePostEvent>(_onToggleLike);
    on<PostCommentEvent>(_onComment);
    on<PostGetCommentsEvent>(_onGetComments);
    on<PostSyncCommentCountEvent>(_onSyncCommentCount);
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

  Future<void> _onGetUserPosts(
    PostGetUserPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    final result = await _getUserPosts(
      userId: event.userId,
      page: event.page,
      limit: event.limit,
    );
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (posts) => emit(PostLoaded(posts)),
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

  Future<void> _onGetComments(
    PostGetCommentsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostCommentsLoading());

    final result = await _getPostComments(event.postId);

    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (comments) => emit(PostCommentsLoaded(comments)),
    );
  }

  void _onSyncCommentCount(
    PostSyncCommentCountEvent event,
    Emitter<PostState> emit,
  ) {
    if (state is! PostLoaded) return;

    final currentState = state as PostLoaded;
    final updatedPosts = currentState.posts.map((post) {
      if (post.id != event.postId || post.commentCount == event.commentCount) {
        return post;
      }

      return post.copyWith(commentCount: event.commentCount);
    }).toList();

    emit(
      PostLoaded(updatedPosts, recentlyCreated: currentState.recentlyCreated),
    );
  }
}
