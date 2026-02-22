part of 'post_bloc.dart';

sealed class PostEvent {
  const PostEvent();
}

class PostGetPostsEvent extends PostEvent {
  final int page;
  final int limit;

  const PostGetPostsEvent({required this.page, required this.limit});
}

class PostCreatePostEvent extends PostEvent {
  final String content;
  final List<PlatformFile> media;

  const PostCreatePostEvent({required this.content, required this.media});
}

class PostDeletePostEvent extends PostEvent {
  final String postId;

  const PostDeletePostEvent({required this.postId});
}

class PostToggleLikePostEvent extends PostEvent {
  final String postId;

  const PostToggleLikePostEvent({required this.postId});
}

class PostCommentEvent extends PostEvent {
  final String postId;
  final String comment;

  const PostCommentEvent({required this.postId, required this.comment});
}

class PostGetCommentsEvent extends PostEvent {
  final String postId;

  const PostGetCommentsEvent({required this.postId});
}

class PostSyncCommentCountEvent extends PostEvent {
  final String postId;
  final int commentCount;

  const PostSyncCommentCountEvent({
    required this.postId,
    required this.commentCount,
  });
}

class PostGetUserPostsEvent extends PostEvent {
  final String userId;
  final int page;
  final int limit;

  const PostGetUserPostsEvent({
    required this.userId,
    this.page = 1,
    this.limit = 20,
  });
}

// ---------------------------------------------------------------------------
// Bookmark events (local only)
// ---------------------------------------------------------------------------

/// Bookmark a post locally. [post] must be the full entity so it can be
/// persisted to the Hive store without a network round-trip.
class PostBookmarkEvent extends PostEvent {
  final Post post;

  const PostBookmarkEvent({required this.post});
}

/// Remove a locally bookmarked post by its [postId].
class PostRemoveBookmarkEvent extends PostEvent {
  final String postId;

  const PostRemoveBookmarkEvent({required this.postId});
}

/// Load all locally bookmarked posts (used by SavedPostsPage).
class PostLoadBookmarkedPostsEvent extends PostEvent {
  const PostLoadBookmarkedPostsEvent();
}

/// Triggered by PostCard on build to refresh the bookmark status set in state.
/// The handler re-loads all bookmarked IDs and merges them into [PostLoaded].
class PostCheckBookmarkStatusEvent extends PostEvent {
  final String postId;

  const PostCheckBookmarkStatusEvent({required this.postId});
}
