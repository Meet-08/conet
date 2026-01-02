part of 'post_detail_bloc.dart';

@immutable
sealed class PostDetailState {}

class PostDetailInitial extends PostDetailState {}

class PostDetailLoading extends PostDetailState {}

class PostDetailLoaded extends PostDetailState {
  final List<Comment> comments;
  PostDetailLoaded(this.comments);
}

class PostDetailFailure extends PostDetailState {
  final String message;
  PostDetailFailure(this.message);
}
