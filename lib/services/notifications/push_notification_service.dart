import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_token_lifecycle.dart';

enum PushPermissionStatus {
  unsupported,
  notDetermined,
  denied,
  provisional,
  authorized,
}

class PushNotificationService {
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription = 'Used for important notifications.';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

  static bool _isInitialized = false;
  static PushTokenLifecycle? _tokenLifecycle;
  static Future<void>? _tokenTracking;
  static final PendingPushTokenRegistration _pendingRegistration =
      PendingPushTokenRegistration();

  static String? get currentToken => _tokenLifecycle?.currentToken;

  /// Activation uses the current FCM registration token as deviceId. Missing
  /// Firebase/transport availability must not produce an empty or invented ID.
  static Future<String?> activationDeviceToken() async {
    if (currentToken != null) return currentToken;
    if (!isSupported) return null;
    await _trackToken();
    return currentToken;
  }

  static bool get hasPendingRegistration =>
      _pendingRegistration.hasPendingRegistration;
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Retries pending registration only when a future backend adapter supplies
  /// its documented request. No endpoint is guessed or called here.
  static Future<bool> retryPendingRegistration(
    PushTokenRegistrationAttempt attempt,
  ) => _pendingRegistration.retry(attempt);

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!isSupported) {
      _isInitialized = true;
      return;
    }

    // No display-permission prompt or granted-status gate is needed here.
    unawaited(_trackToken());
    await _initializeLocalNotifications();
    await _configureForegroundPresentation();
    _listenForegroundMessages();
    _listenNotificationTapEvents();
    await _handleInitialMessage();
    // FCM may wait on network/Play Services. Keep app startup usable offline.

    _isInitialized = true;
  }

  /// Reads permission state without presenting an OS prompt.
  static Future<PushPermissionStatus> getPermissionStatus() async {
    if (!isSupported) return PushPermissionStatus.unsupported;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return _permissionStatus(settings.authorizationStatus);
  }

  /// Requests notification access only after an in-app user action.
  static Future<PushPermissionStatus> requestPermissionFromUser() async {
    if (!isSupported) return PushPermissionStatus.unsupported;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    unawaited(_trackToken());
    return _permissionStatus(settings.authorizationStatus);
  }

  /// Read/retry on foreground return; never deletes tokens, changes auto-init,
  /// grants notification access or submits anything to an undocumented API.
  static Future<void> refreshTokenIfAvailable() async {
    if (!_isInitialized || !isSupported) return;
    await _trackToken();
  }

  static PushPermissionStatus _permissionStatus(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized => PushPermissionStatus.authorized,
        AuthorizationStatus.provisional => PushPermissionStatus.provisional,
        AuthorizationStatus.denied => PushPermissionStatus.denied,
        AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
      };

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _configureForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static void _listenNotificationTapEvents() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint(
          '[PushNotificationService] onMessageOpenedApp: ${message.messageId}',
        );
      }
    });
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && kDebugMode) {
      debugPrint(
        '[PushNotificationService] initialMessage: ${initialMessage.messageId}',
      );
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      title ?? '',
      body ?? '',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> _trackToken() =>
      _tokenTracking ??= _trackTokenOnce().whenComplete(
        () => _tokenTracking = null,
      );

  static Future<void> _trackTokenOnce() async {
    try {
      final messaging = FirebaseMessaging.instance;
      _tokenLifecycle ??= PushTokenLifecycle(
        fetchCurrentToken:
            PushTokenAcquirer(
              fetchToken: messaging.getToken,
              fetchApnsToken: Platform.isIOS ? messaging.getAPNSToken : null,
            ).call,
        tokenRefreshes: messaging.onTokenRefresh,
        onTokenChanged: (token) {
          _pendingRegistration.markPending(token);
          // Includes automatic recovery/rotation, without exposing token values.
          if (kDebugMode) {
            debugPrint(
              '[PushNotificationService] tokenAvailable=true; registrationPending=$hasPendingRegistration',
            );
          }
        },
      );
      await _tokenLifecycle!.start();
      if (kDebugMode) {
        debugPrint(
          '[PushNotificationService] tokenAvailable=${currentToken != null}; '
          'registrationPending=$hasPendingRegistration',
        );
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[PushNotificationService] Token setup failed: ${error.code}',
        );
      }
    }
  }
}
