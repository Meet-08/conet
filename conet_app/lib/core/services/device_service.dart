import 'dart:io';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/services/notification_config_service.dart';
import 'package:conet_app/feature/device/domain/usecases/register_device_usecase.dart';
import 'package:conet_app/feature/device/domain/usecases/remove_device_usecase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  final RegisterDeviceUseCase _registerDeviceUseCase;
  final RemoveDeviceUseCase _removeDeviceUseCase;
  final AppUserCubit _appUserCubit;
  final NotificationConfigService _notificationConfigService;

  DeviceService(
    this._registerDeviceUseCase,
    this._removeDeviceUseCase,
    this._appUserCubit,
    this._notificationConfigService,
  );

  Future<void> init() async {
    // Request notification permission (Android 13+, iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Only proceed if permission was granted
    if (settings.authorizationStatus != AuthorizationStatus.denied) {
      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        _registerToken(fcmToken);
      });

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _notificationConfigService.showNotification(message);
      });

      // Register current token if user is logged in
      if (_appUserCubit.state is AppUserAuthenticated) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          _registerToken(token);
        }
      }
    }
  }

  Future<void> _registerToken(String fcmToken) async {
    if (_appUserCubit.state is! AppUserAuthenticated) return;

    String platform = 'unknown';
    if (kIsWeb) {
      platform = 'web';
    } else if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    }

    await _registerDeviceUseCase(
      RegisterDeviceParams(fcmToken: fcmToken, platform: platform),
    );
  }

  Future<void> removeCurrentDevice() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _removeDeviceUseCase(RemoveDeviceParams(fcmToken: token));
    }
  }
}
