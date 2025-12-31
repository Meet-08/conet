part of 'post_bloc.dart';

@immutable
sealed class PostState {
  const PostState();
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostLoaded extends PostState {
  final List<Post> posts;
  const PostLoaded(this.posts);
}

class PostFailure extends PostState {
  final String message;
  const PostFailure(this.message);
}
