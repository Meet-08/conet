import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserUnknown());

  bool get isLoggedIn => state is AppUserAuthenticated;
  bool get isUnknown => state is AppUserUnknown;

  void updateUser(User? user) {
    if (user == null) {
      emit(AppUserUnauthenticated());
    } else {
      emit(AppUserAuthenticated(user));
    }
  }

  void logout() {
    emit(AppUserUnauthenticated());
  }

  // ── Notification count helpers ──────────────────────────────

  void updateUnseenNotificationCount(int count) {
    final current = state;
    if (current is! AppUserAuthenticated) return;

    final updated = _copyUserWith(
      current.user,
      unseenNotificationCount: count < 0 ? 0 : count,
    );
    emit(AppUserAuthenticated(updated));
  }

  void incrementNotificationCount() {
    final current = state;
    if (current is! AppUserAuthenticated) return;

    final updated = _copyUserWith(
      current.user,
      unseenNotificationCount: current.user.unseenNotificationCount + 1,
    );
    emit(AppUserAuthenticated(updated));
  }

  void resetNotificationCount() {
    final current = state;
    if (current is! AppUserAuthenticated) return;
    if (current.user.unseenNotificationCount == 0) return; // no-op

    final updated = _copyUserWith(current.user, unseenNotificationCount: 0);
    emit(AppUserAuthenticated(updated));
  }

  // ── Online presence helper ─────────────────────────────────

  void updateOnlineStatus(bool isOnline) {
    final current = state;
    if (current is! AppUserAuthenticated) return;
    if (current.user.isOnline == isOnline) return; // no-op

    final updated = _copyUserWith(current.user, isOnline: isOnline);
    emit(AppUserAuthenticated(updated));
  }

  // ── Internal helper ────────────────────────────────────────

  /// Creates a new [User] with selectively overridden fields.
  /// Works regardless of whether the runtime type is [UserModel] or [User].
  User _copyUserWith(
    User user, {
    int? unseenNotificationCount,
    bool? isOnline,
  }) {
    if (user is UserModel) {
      return user.copyWith(
        unseenNotificationCount: unseenNotificationCount,
        isOnline: isOnline,
      );
    }
    // Fallback: reconstruct from base User fields
    return UserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.username,
      phone: user.phone,
      profilePicUrl: user.profilePicUrl,
      userRole: user.userRole,
      unseenNotificationCount:
          unseenNotificationCount ?? user.unseenNotificationCount,
      isOnline: isOnline ?? user.isOnline,
    );
  }
}
