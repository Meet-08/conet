import 'package:conet_app/feature/post/domain/entities/post.dart';

abstract interface class PostBookmarkLocalDataSource {
  /// Saves [post] to the local bookmark store.
  Future<void> bookmarkPost(Post post);

  /// Removes the post identified by [postId] from the bookmark store.
  Future<void> removeBookmark(String postId);

  /// Returns all locally bookmarked posts, ordered by bookmarked time (newest first).
  Future<List<Post>> getBookmarkedPosts();

  /// Returns `true` if the post identified by [postId] is bookmarked locally.
  Future<bool> isPostBookmarked(String postId);
}
