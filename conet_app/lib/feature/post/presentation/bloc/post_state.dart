part of 'post_bloc.dart';

@immutable
sealed class PostState {
  const PostState();
}

final class PostInitial extends PostState {}

final class PostLoading extends PostState {}

final class PostLoaded extends PostState {
  final List<Post> posts;

  const PostLoaded(this.posts);
}

final class PostActionInProgress extends PostState {}

final class PostActionSuccess extends PostState {}

final class PostFailure extends PostState {
  final String message;
  const PostFailure(this.message);
}
