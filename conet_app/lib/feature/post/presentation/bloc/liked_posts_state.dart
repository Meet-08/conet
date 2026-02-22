part of 'liked_posts_bloc.dart';

@immutable
sealed class LikedPostsState {
  const LikedPostsState();
}

class LikedPostsInitial extends LikedPostsState {}

class LikedPostsLoading extends LikedPostsState {}

class LikedPostsLoaded extends LikedPostsState {
  final List<Post> posts;

  const LikedPostsLoaded(this.posts);
}

class LikedPostsFailure extends LikedPostsState {
  final String message;

  const LikedPostsFailure(this.message);
}
