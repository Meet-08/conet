part of 'liked_posts_bloc.dart';

sealed class LikedPostsEvent {
  const LikedPostsEvent();
}

class LikedPostsFetchEvent extends LikedPostsEvent {
  final int page;
  final int limit;

  const LikedPostsFetchEvent({this.page = 1, this.limit = 20});
}
