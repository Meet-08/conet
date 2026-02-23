import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/cubit/presence_cubit.dart';
import 'package:conet_app/core/common/data_sources/presence_data_source.dart';

/// Orchestrates online-presence tracking.
///
/// * Subscribes to [PresenceDataSource] for join/leave events.
/// * Pushes the full set of online user IDs into [PresenceCubit].
/// * Also updates the current user's `isOnline` in [AppUserCubit].
///
/// Call [start] after login, [dispose] on logout.
class PresenceService {
  final PresenceDataSource _presenceDataSource;
  final PresenceCubit _presenceCubit;
  final AppUserCubit _appUserCubit;

  StreamSubscription<Set<String>>? _subscription;

  PresenceService({
    required PresenceDataSource presenceDataSource,
    required PresenceCubit presenceCubit,
    required AppUserCubit appUserCubit,
  }) : _presenceDataSource = presenceDataSource,
       _presenceCubit = presenceCubit,
       _appUserCubit = appUserCubit;

  /// Start tracking presence for [userId].
  void start(String userId) {
    _subscription?.cancel();
    _subscription = _presenceDataSource.watchOnlineUsers(userId).listen((
      onlineUserIds,
    ) {
      // Update the global set of online users (for ChatAppBar, etc.)
      _presenceCubit.setOnlineUsers(onlineUserIds);

      // Also update the current user's own isOnline flag
      _appUserCubit.updateOnlineStatus(onlineUserIds.contains(userId));
    });
  }

  /// Stop tracking and release resources.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _presenceCubit.clear();
    await _presenceDataSource.dispose();
  }
}
