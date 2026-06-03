import 'dart:async';

import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_bookmark.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_bookmarks.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_user_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_remove_bookmark.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:conet_app/feature/post/domain/usecases/post_record_impressions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

part 'post_event.dart';
part 'post_state.dart';

/// Debounce transformer that waits [duration] of inactivity before forwarding
/// the latest event, preventing rapid-fire API calls.
EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostGetPosts _getPosts;
  final PostGetUserPosts _getUserPosts;
  final PostCreate _createPost;
  final PostDelete _deletePost;
  final PostToggleLike _toggleLike;
  final PostComment _commentPost;
  final PostGetPostComments _getPostComments;
  final PostBookmark _bookmarkPost;
  final PostRemoveBookmark _removeBookmark;
  final PostGetBookmarks _getBookmarks;
  final PostRecordImpressions _recordImpressions;
 
  /// Tracks post IDs with an in-flight like API call to prevent duplicates.
  final Set<String> _likingPostIds = {};

  /// Pending post impressions to be flushed to backend.
  final Set<String> _pendingImpressions = {};
 
  PostBloc({
    required PostGetPosts getPosts,
    required PostGetUserPosts getUserPosts,
    required PostCreate createPost,
    required PostDelete deletePost,
    required PostToggleLike toggleLike,
    required PostComment commentPost,
    required PostGetPostComments getPostComments,
    required PostBookmark bookmarkPost,
    required PostRemoveBookmark removeBookmark,
    required PostGetBookmarks getBookmarks,
    required PostRecordImpressions recordImpressions,
  }) : _getPosts = getPosts,
       _getUserPosts = getUserPosts,
       _createPost = createPost,
       _deletePost = deletePost,
       _toggleLike = toggleLike,
       _commentPost = commentPost,
       _getPostComments = getPostComments,
       _bookmarkPost = bookmarkPost,
       _removeBookmark = removeBookmark,
       _getBookmarks = getBookmarks,
       _recordImpressions = recordImpressions,
       super(PostInitial()) {
    on<PostGetPostsEvent>(_onGetPosts);
    on<PostGetUserPostsEvent>(_onGetUserPosts);
    on<PostCreatePostEvent>(_onCreatePost);
    on<PostDeletePostEvent>(_onDeletePost);
    on<PostToggleLikePostEvent>(
      _onToggleLike,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<PostCommentEvent>(_onComment);
    on<PostGetCommentsEvent>(_onGetComments);
    on<PostSyncCommentCountEvent>(_onSyncCommentCount);
    // Bookmark events
    on<PostBookmarkEvent>(_onBookmarkPost);
    on<PostRemoveBookmarkEvent>(_onRemoveBookmark);
    on<PostLoadBookmarkedPostsEvent>(_onLoadBookmarkedPosts);
    on<PostCheckBookmarkStatusEvent>(_onCheckBookmarkStatus);
    on<PostMarkSeenEvent>(_onMarkSeen);
    on<PostFlushImpressionsEvent>(_onFlushImpressions);
  }

  Future<void> _onGetPosts(
    PostGetPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    final result = await _getPosts(page: event.page, limit: event.limit);

    // Do not use async callbacks inside fold — fold doesn't await them,
    // which causes emit-after-completion assertion errors in Bloc.
    String? failureMessage;
    List<Post>? posts;
    result.fold(
      (failure) => failureMessage = failure.message,
      (p) => posts = p,
    );

    if (failureMessage != null) {
      emit(PostFailure(failureMessage!));
    } else if (posts != null) {
      final bookmarkedIds = await _loadBookmarkedIds();
      emit(PostLoaded(posts!, bookmarkedPostIds: bookmarkedIds));
    }
  }

  Future<void> _onGetUserPosts(
    PostGetUserPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    final result = await _getUserPosts(
      userId: event.userId,
      page: event.page,
      limit: event.limit,
    );

    String? failureMessage;
    List<Post>? posts;
    result.fold(
      (failure) => failureMessage = failure.message,
      (p) => posts = p,
    );

    if (failureMessage != null) {
      emit(PostFailure(failureMessage!));
    } else if (posts != null) {
      final bookmarkedIds = await _loadBookmarkedIds();
      emit(PostLoaded(posts!, bookmarkedPostIds: bookmarkedIds));
    }
  }

  Future<void> _onCreatePost(
    PostCreatePostEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _createPost(
      content: event.content,
      media: event.media,
    );

    String? failureMessage;
    Post? createdPost;
    result.fold(
      (failure) => failureMessage = failure.message,
      (post) => createdPost = post,
    );

    if (failureMessage != null) {
      emit(PostFailure(failureMessage!));
      return;
    }

    if (createdPost == null) return;

    final currentState = state is PostLoaded ? state as PostLoaded : null;
    final currentPosts = currentState?.posts ?? const <Post>[];

    final feedResult = await _getPosts(page: 1, limit: 20);
    List<Post> mergedPosts = [
      createdPost!,
      ...currentPosts.where((post) => post.id != createdPost!.id),
    ];

    feedResult.fold((_) {}, (posts) {
      mergedPosts = [
        createdPost!,
        ...posts.where((post) => post.id != createdPost!.id),
      ];
    });

    final bookmarkedIds =
        currentState?.bookmarkedPostIds ?? await _loadBookmarkedIds();

    emit(
      PostLoaded(
        mergedPosts,
        recentlyCreated: true,
        bookmarkedPostIds: bookmarkedIds,
      ),
    );
  }

  Future<void> _onDeletePost(
    PostDeletePostEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _deletePost(event.postId);

    result.fold((failure) => emit(PostFailure(failure.message)), (_) {});
  }

  Future<void> _onToggleLike(
    PostToggleLikePostEvent event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PostLoaded && currentState is! PostBookmarksLoaded) {
      return;
    }

    // Skip if there's already an in-flight like request for this post
    if (_likingPostIds.contains(event.postId)) return;
    _likingPostIds.add(event.postId);

    // Both PostLoaded and PostBookmarksLoaded carry a posts list
    final List<Post> originalPosts = switch (currentState) {
      PostLoaded s => s.posts,
      PostBookmarksLoaded s => s.posts,
      _ => [],
    };

    final updatedPosts = originalPosts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
        );
      }
      return post;
    }).toList();

    // Optimistic update — preserve the correct state type
    if (currentState is PostLoaded) {
      emit(
        PostLoaded(
          updatedPosts,
          bookmarkedPostIds: currentState.bookmarkedPostIds,
        ),
      );
    } else {
      emit(PostBookmarksLoaded(updatedPosts));
    }

    final result = await _toggleLike(event.postId);
    _likingPostIds.remove(event.postId);

    await result.fold(
      (failure) async {
        // Rollback on failure
        if (currentState is PostLoaded) {
          emit(
            PostLoaded(
              originalPosts,
              bookmarkedPostIds: currentState.bookmarkedPostIds,
            ),
          );
        } else {
          emit(PostBookmarksLoaded(originalPosts));
        }
      },
      (_) async {
        // Sync updated like state back to Hive for bookmarked posts so that
        // SavedPostsPage always shows fresh like counts after toggling.
        final updatedPost = updatedPosts
            .where((p) => p.id == event.postId)
            .firstOrNull;
        if (updatedPost == null) return;

        final isBookmarked = switch (currentState) {
          // Feed: check the bookmarked IDs set for this post
          PostLoaded s => s.bookmarkedPostIds.contains(event.postId),
          // SavedPostsPage: every listed post is bookmarked by definition
          PostBookmarksLoaded _ => true,
          _ => false,
        };

        if (isBookmarked) {
          // Overwrite the Hive record with the updated post data (new like count / isLiked)
          await _bookmarkPost(updatedPost);
        }
      },
    );
  }

  Future<void> _onComment(
    PostCommentEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _commentPost(event.postId, event.comment);

    result.fold((failure) => emit(PostFailure(failure.message)), (_) {});
  }

  Future<void> _onGetComments(
    PostGetCommentsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostCommentsLoading());

    final result = await _getPostComments(event.postId);

    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (comments) => emit(PostCommentsLoaded(comments)),
    );
  }

  void _onSyncCommentCount(
    PostSyncCommentCountEvent event,
    Emitter<PostState> emit,
  ) {
    if (state is! PostLoaded) return;

    final currentState = state as PostLoaded;
    final updatedPosts = currentState.posts.map((post) {
      if (post.id != event.postId || post.commentCount == event.commentCount) {
        return post;
      }
      return post.copyWith(commentCount: event.commentCount);
    }).toList();

    emit(
      PostLoaded(
        updatedPosts,
        recentlyCreated: currentState.recentlyCreated,
        bookmarkedPostIds: currentState.bookmarkedPostIds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bookmark handlers
  // ---------------------------------------------------------------------------

  Future<void> _onBookmarkPost(
    PostBookmarkEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _bookmarkPost(event.post);

    result.fold((failure) => emit(PostFailure(failure.message)), (_) {
      if (state is PostLoaded) {
        final current = state as PostLoaded;
        final updatedIds = {...current.bookmarkedPostIds, event.post.id};
        emit(
          PostLoaded(
            current.posts,
            recentlyCreated: current.recentlyCreated,
            bookmarkedPostIds: updatedIds,
          ),
        );
      }
    });
  }

  Future<void> _onRemoveBookmark(
    PostRemoveBookmarkEvent event,
    Emitter<PostState> emit,
  ) async {
    final result = await _removeBookmark(event.postId);

    result.fold((failure) => emit(PostFailure(failure.message)), (_) {
      if (state is PostLoaded) {
        final current = state as PostLoaded;
        final updatedIds = {...current.bookmarkedPostIds}..remove(event.postId);
        emit(
          PostLoaded(
            current.posts,
            recentlyCreated: current.recentlyCreated,
            bookmarkedPostIds: updatedIds,
          ),
        );
      } else if (state is PostBookmarksLoaded) {
        // Remove from saved posts list immediately
        final current = state as PostBookmarksLoaded;
        final updatedPosts = current.posts
            .where((p) => p.id != event.postId)
            .toList();
        emit(PostBookmarksLoaded(updatedPosts));
      }
    });
  }

  Future<void> _onLoadBookmarkedPosts(
    PostLoadBookmarkedPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());

    final result = await _getBookmarks();
    result.fold(
      (failure) => emit(PostFailure(failure.message)),
      (posts) => emit(PostBookmarksLoaded(posts)),
    );
  }

  /// Refreshes the [PostLoaded.bookmarkedPostIds] set from the local store.
  /// Dispatched by [PostCard] on first build. No-op if state is not [PostLoaded].
  Future<void> _onCheckBookmarkStatus(
    PostCheckBookmarkStatusEvent event,
    Emitter<PostState> emit,
  ) async {
    if (state is! PostLoaded) return;

    final current = state as PostLoaded;
    final ids = await _loadBookmarkedIds();

    // Only emit if the bookmarked-IDs set actually changed
    if (ids.difference(current.bookmarkedPostIds).isNotEmpty ||
        current.bookmarkedPostIds.difference(ids).isNotEmpty) {
      emit(
        PostLoaded(
          current.posts,
          recentlyCreated: current.recentlyCreated,
          bookmarkedPostIds: ids,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Loads all bookmarked post IDs from local store.  Returns empty set on error.
  Future<Set<String>> _loadBookmarkedIds() async {
    final result = await _getBookmarks();
    return result.fold(
      (_) => const <String>{},
      (posts) => posts.map((p) => p.id).toSet(),
    );
  }

  void _onMarkSeen(PostMarkSeenEvent event, Emitter<PostState> emit) {
    _pendingImpressions.add(event.postId);
  }

  Future<void> _onFlushImpressions(
    PostFlushImpressionsEvent event,
    Emitter<PostState> emit,
  ) async {
    if (_pendingImpressions.isEmpty) return;
    final copy = _pendingImpressions.toList();
    _pendingImpressions.clear();

    final result = await _recordImpressions(copy);
    result.fold(
      (failure) {
        debugPrint("Failed to flush impressions: ${failure.message}");
      },
      (_) {
        debugPrint("Impressions flushed successfully");
      },
    );
  }
}
