part of 'post_bloc.dart';

@immutable
sealed class PostState {
  const PostState();
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostLoaded extends PostState {
  final List<Post> posts;
  final bool recentlyCreated;

  /// IDs of posts the current user has bookmarked locally (Hive).
  /// Updated whenever bookmark events are handled or posts are refreshed.
  final Set<String> bookmarkedPostIds;

  const PostLoaded(
    this.posts, {
    this.recentlyCreated = false,
    this.bookmarkedPostIds = const {},
  });
}

/// Emitted when [PostLoadBookmarkedPostsEvent] completes.
/// Used exclusively by SavedPostsPage.
class PostBookmarksLoaded extends PostState {
  final List<Post> posts;

  const PostBookmarksLoaded(this.posts);
}

class PostCommentsLoading extends PostState {}

class PostCommentsLoaded extends PostState {
  final List<Comment> comments;

  const PostCommentsLoaded(this.comments);
}

class PostFailure extends PostState {
  final String message;
  const PostFailure(this.message);
}
