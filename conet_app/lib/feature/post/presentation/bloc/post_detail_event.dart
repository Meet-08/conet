part of 'post_detail_bloc.dart';

@immutable
sealed class PostDetailEvent {}

class PostDetailWatchCommentsEvent extends PostDetailEvent {
  final String postId;
  PostDetailWatchCommentsEvent({required this.postId});
}

class PostDetailCommentsUpdatedEvent extends PostDetailEvent {
  final List<Comment> comments;

  PostDetailCommentsUpdatedEvent({required this.comments});
}

class PostDetailCommentsFailedEvent extends PostDetailEvent {
  final String message;

  PostDetailCommentsFailedEvent({required this.message});
}

class PostDetailAddCommentEvent extends PostDetailEvent {
  final String postId;
  final String comment;
  final Comment optimisticComment;

  PostDetailAddCommentEvent({
    required this.postId,
    required this.comment,
    required this.optimisticComment,
  });
}
