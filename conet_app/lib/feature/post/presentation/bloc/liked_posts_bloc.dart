import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_liked_posts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'liked_posts_event.dart';
part 'liked_posts_state.dart';

class LikedPostsBloc extends Bloc<LikedPostsEvent, LikedPostsState> {
  final PostGetLikedPosts _getLikedPosts;

  LikedPostsBloc({required PostGetLikedPosts getLikedPosts})
    : _getLikedPosts = getLikedPosts,
      super(LikedPostsInitial()) {
    on<LikedPostsFetchEvent>(_onFetch);
  }

  Future<void> _onFetch(
    LikedPostsFetchEvent event,
    Emitter<LikedPostsState> emit,
  ) async {
    emit(LikedPostsLoading());

    final result = await _getLikedPosts(page: event.page, limit: event.limit);

    result.fold(
      (failure) => emit(LikedPostsFailure(failure.message)),
      (posts) => emit(LikedPostsLoaded(posts)),
    );
  }
}
