import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the set of currently-online user IDs.
///
/// Lives in `core` because online status is a cross-cutting concern
/// used by messages, profiles, and potentially other features.
class PresenceCubit extends Cubit<Set<String>> {
  PresenceCubit() : super(const {});

  /// Replace the entire online-user set (used on sync).
  void setOnlineUsers(Set<String> userIds) {
    emit(userIds);
  }

  /// Check if a specific user is online.
  bool isUserOnline(String userId) => state.contains(userId);

  /// Clear all presence state (e.g. on logout).
  void clear() => emit(const {});
}
