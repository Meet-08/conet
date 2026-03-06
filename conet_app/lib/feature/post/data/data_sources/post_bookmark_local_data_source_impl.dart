import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/post/data/data_sources/post_bookmark_local_data_source.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed implementation of [PostBookmarkLocalDataSource].
///
/// Box name: `bookmarked_posts`
/// Key: postId (String)
/// Value: serialized post fields as a dynamic Map
///
/// The box MUST be opened via `Hive.openBox(PostBookmarkLocalDataSourceImpl.boxName)`
/// before this class is used (done in [initDependencies]).
class PostBookmarkLocalDataSourceImpl implements PostBookmarkLocalDataSource {
  static const String boxName = 'bookmarked_posts';

  Box get _box => Hive.box(boxName);

  @override
  Future<void> bookmarkPost(Post post) async {
    await _box.put(post.id, _postToMap(post));
  }

  @override
  Future<void> removeBookmark(String postId) async {
    await _box.delete(postId);
  }

  @override
  Future<List<Post>> getBookmarkedPosts() async {
    final posts = _box.values
        .map((raw) => _postFromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
    // Newest first — Hive preserves insertion order; reverse for newest-first
    return posts.reversed.toList();
  }

  @override
  Future<bool> isPostBookmarked(String postId) async {
    return _box.containsKey(postId);
  }

  // ---------------------------------------------------------------------------
  // Serialization helpers (data layer only — no Hive outside this file)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _postToMap(Post post) => {
    'id': post.id,
    'user': {
      'id': post.user.id,
      'email': post.user.email,
      'first_name': post.user.firstName,
      'last_name': post.user.lastName,
      'username': post.user.username,
      'profile_pic_url': post.user.profilePicUrl,
      'user_role': post.user.userRole.name,
    },
    'content': post.content,
    'media_urls': List<String>.from(post.mediaUrls),
    'like_count': post.likeCount,
    'comment_count': post.commentCount,
    'is_liked': post.isLiked,
    'created_at': post.createdAt.toIso8601String(),
  };

  Post _postFromMap(Map<String, dynamic> map) {
    final userMap = Map<String, dynamic>.from(map['user'] as Map);
    return PostModel(
      id: map['id'] as String,
      user: User.fromJson(userMap),
      content: map['content'] as String,
      mediaUrls: List<String>.from(map['media_urls'] as List),
      likeCount: (map['like_count'] as num).toInt(),
      commentCount: (map['comment_count'] as num).toInt(),
      isLiked: map['is_liked'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
