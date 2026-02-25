part of 'post_detail_bloc.dart';

@immutable
sealed class PostDetailState {}

class PostDetailInitial extends PostDetailState {}

class PostDetailLoading extends PostDetailState {}

class PostDetailPostLoaded extends PostDetailState {
  final Post post;
  PostDetailPostLoaded(this.post);
}

class PostDetailPostFailure extends PostDetailState {
  final String message;
  PostDetailPostFailure(this.message);
}

class PostDetailLoaded extends PostDetailState {
  final List<Comment> comments;
  PostDetailLoaded(this.comments);
}

class PostDetailFailure extends PostDetailState {
  final String message;
  PostDetailFailure(this.message);
}
