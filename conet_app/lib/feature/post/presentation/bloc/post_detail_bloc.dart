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
    // Optimistic Update
    if (state is PostDetailLoaded) {
      final currentComments = (state as PostDetailLoaded).comments;
      emit(PostDetailLoaded([...currentComments, event.optimisticComment]));
    }

    final result = await _commentPost(event.postId, event.comment);

    result.fold(
      (failure) {
        // Revert optimistic update on failure
        // For simplicity, we can emit failure state or reload.
        // Emitting failure might replace the list with error, which is harsh.
        // Ideally we should keep the list but show error (e.g. snackbar via listener).
        // Here we just emit failure as per existing pattern, which shows error UI.
        emit(PostDetailFailure(failure.message));
        // You might want to reload to restore valid state
        add(PostDetailGetCommentsEvent(postId: event.postId));
      },
      (_) {
        // Success - Do nothing (retain optimistic comment)
        // No reload needed as per user request
      },
    );
  }
}
