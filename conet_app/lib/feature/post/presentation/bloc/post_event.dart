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
