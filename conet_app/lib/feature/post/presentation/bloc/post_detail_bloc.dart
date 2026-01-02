import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_detail_event.dart';
part 'post_detail_state.dart';

class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  final PostGetPostComments _getPostComments;
  final PostComment _commentPost;

  PostDetailBloc({
    required PostGetPostComments getPostComments,
    required PostComment commentPost,
  }) : _getPostComments = getPostComments,
       _commentPost = commentPost,
       super(PostDetailInitial()) {
    on<PostDetailGetCommentsEvent>(_onGetComments);
    on<PostDetailAddCommentEvent>(_onAddComment);
  }

  Future<void> _onGetComments(
    PostDetailGetCommentsEvent event,
    Emitter<PostDetailState> emit,
  ) async {
    emit(PostDetailLoading());
    final result = await _getPostComments(event.postId);
    result.fold(
      (failure) => emit(PostDetailFailure(failure.message)),
      (comments) => emit(PostDetailLoaded(comments)),
    );
  }

  Future<void> _onAddComment(
    PostDetailAddCommentEvent event,
    Emitter<PostDetailState> emit,
  ) async {
    // We don't necessarily need to emit loading for adding a comment if we want optimistic UI or just keeping the list
    // But for simplicity, let's keep the current state or minor loading.
    // Actually, usually we might want to re-fetch or append.
    // Let's implement simple re-fetch strategy for now.

    final result = await _commentPost(event.postId, event.comment);

    result.fold((failure) => emit(PostDetailFailure(failure.message)), (_) {
      // Success, trigger reload
      add(PostDetailGetCommentsEvent(postId: event.postId));
    });
  }
}
