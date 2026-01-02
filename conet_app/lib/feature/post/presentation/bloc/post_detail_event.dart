part of 'post_detail_bloc.dart';

@immutable
sealed class PostDetailEvent {}

class PostDetailGetCommentsEvent extends PostDetailEvent {
  final String postId;
  PostDetailGetCommentsEvent({required this.postId});
}

class PostDetailAddCommentEvent extends PostDetailEvent {
  final String postId;
  final String comment;
  PostDetailAddCommentEvent({required this.postId, required this.comment});
}
