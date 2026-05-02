import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PostModel.fromJson maps nested author is_following', () {
    final post = PostModel.fromJson({
      'id': 'post-1',
      'user': {
        'id': 'user-1',
        'email': 'author@example.com',
        'first_name': 'Post',
        'last_name': 'Author',
        'username': 'post_author',
        'profile_pic_url': null,
        'user_role': 'user',
        'is_following': true,
      },
      'content': 'hello',
      'media_urls': <String>[],
      'like_count': 0,
      'comment_count': 0,
      'is_liked': false,
      'created_at': '2026-05-02T10:00:00.000Z',
    });

    expect(post.user.isFollowing, true);
  });
}
