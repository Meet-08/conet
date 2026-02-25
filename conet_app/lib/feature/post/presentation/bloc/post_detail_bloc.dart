import 'dart:async';

import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_post_comments.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_detail_event.dart';
part 'post_detail_state.dart';

class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  final PostGetPostComments _getPostComments;
  final PostWatchPostComments _watchPostComments;
  final PostComment _commentPost;
  final PostGetPost _getPost;
  StreamSubscription<List<Comment>>? _commentsSubscription;

  PostDetailBloc({
    required PostGetPostComments getPostComments,
    required PostWatchPostComments watchPostComments,
    required PostComment commentPost,
    required PostGetPost getPost,
  }) : _getPostComments = getPostComments,
       _watchPostComments = watchPostComments,
       _commentPost = commentPost,
       _getPost = getPost,
       super(PostDetailInitial()) {
    on<PostDetailFetchPostEvent>(_onFetchPost);
    on<PostDetailWatchCommentsEvent>(_onWatchComments);
    on<PostDetailCommentsUpdatedEvent>(_onCommentsUpdated);
    on<PostDetailCommentsFailedEvent>(_onCommentsFailed);
    on<PostDetailAddCommentEvent>(_onAddComment);
  }

  @override
  Future<void> close() {
    _commentsSubscription?.cancel();
    return super.close();
  }

  void _onWatchComments(
    PostDetailWatchCommentsEvent event,
    Emitter<PostDetailState> emit,
  ) {
    _commentsSubscription?.cancel();
    _commentsSubscription = _watchPostComments(event.postId).listen(
      (comments) => add(PostDetailCommentsUpdatedEvent(comments: comments)),
      onError: (error) =>
          add(PostDetailCommentsFailedEvent(message: error.toString())),
    );
  }

  Future<void> _onFetchPost(
    PostDetailFetchPostEvent event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(PostDetailLoading());
    final result = await _getPost(event.postId);
    result.fold((failure) => emit(PostDetailPostFailure(failure.message)), (
      post,
    ) {
      emit(PostDetailPostLoaded(post));
    });
  }

  void _onCommentsUpdated(
    PostDetailCommentsUpdatedEvent event,
    Emitter<PostDetailState> emit,
  ) {
    emit(PostDetailLoaded(event.comments));
  }

  void _onCommentsFailed(
    PostDetailCommentsFailedEvent event,
    Emitter<PostDetailState> emit,
  ) {
    emit(PostDetailFailure(event.message));
  }

  Future<void> _onAddComment(
    PostDetailAddCommentEvent event,
    Emitter<PostDetailState> emit,
  ) async {
    // Optimistic Update
    if (state is PostDetailLoaded) {
      final currentComments = (state as PostDetailLoaded).comments;
      emit(PostDetailLoaded([...currentComments, event.optimisticComment]));
    }

    final result = await _commentPost(event.postId, event.comment);

    if (result.isLeft()) {
      final failure = result.swap().getOrElse(
        (_) => throw StateError('Unexpected right value while reading failure'),
      );
      emit(PostDetailFailure(failure.message));
      add(PostDetailWatchCommentsEvent(postId: event.postId));
      return;
    }

    final latestComments = await _getPostComments(event.postId);
    latestComments.fold((_) {}, (comments) => emit(PostDetailLoaded(comments)));
  }
}
