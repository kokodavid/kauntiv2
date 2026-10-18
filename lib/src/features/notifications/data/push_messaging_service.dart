import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../services/app_logger.dart';
import '../domain/push_destination.dart';

/// The phone side of push: Firebase, the OS permission, the device token
/// and the taps. Everything returns plain domain values, so the rest of the
/// app never touches Firebase types.
abstract interface class PushMessagingService {
  /// Starts Firebase once. False when this build has no Firebase config or
  /// startup failed, which turns push off without affecting anything else.
  Future<bool> start();

  Future<PushPermission> permission();

  Future<String?> token();

  /// iOS only: the token Apple gave the phone (null elsewhere or before it
  /// arrives). Shown in the dev Push status screen.
  Future<String?> apnsToken();

  Future<void> deleteToken();

  Stream<String> get tokenRefreshes;

  /// A notification tapped while the app was in the background.
  Stream<PushTap> get taps;

  /// The notification that cold-started the app, once.
  Future<PushTap?> initialTap();

  /// A notification that arrived while the app is in front.
  Stream<PushForegroundMessage> get foreground;
}

class FirebasePushMessagingService implements PushMessagingService {
  FirebasePushMessagingService(this.settings);

  static const _logger = AppLogger.push();
  static const _iosBundleId = 'com.giglab.kaunti47.app';

  final FirebaseSettings settings;
  Future<bool>? _started;

  @override
  Future<bool> start() => _started ??= _start();

  Future<bool> _start() async {
    if (!settings.isConfigured) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: settings.apiKey,
            appId: Platform.isIOS ? settings.iosAppId : settings.androidAppId,
            messagingSenderId: settings.messagingSenderId,
            projectId: settings.projectId,
            iosBundleId: _iosBundleId,
          ),
        );
      }
      // In front, the app shows its own small banner.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      await _createAndroidChannels();
      return true;
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Push could not start.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// The channels the server names in its Android payload, created up front
  /// so a message never lands on a channel that does not exist.
  Future<void> _createAndroidChannels() async {
    if (!Platform.isAndroid) return;
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'announcements',
        'Announcements',
        description: 'News about Kaunti47.',
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'reviews',
        'Reviews',
        description: 'When something you sent has been reviewed.',
        importance: Importance.high,
      ),
    );
  }

  @override
  Future<PushPermission> permission() async {
    if (!await start()) return PushPermission.unknown;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermission.granted,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.unknown,
    };
  }

  @override
  Future<String?> token() async {
    if (!await start()) return null;
    final messaging = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      // Already allowed (for example from Home's card): this re-registers
      // for remote notifications without showing a prompt. Not asked yet:
      // left alone, so Firebase never shows its own prompt at the wrong
      // moment.
      final status = (await messaging.getNotificationSettings())
          .authorizationStatus;
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        await messaging.requestPermission();
      }
    }
    return messaging.getToken();
  }

  @override
  Future<String?> apnsToken() async {
    if (!Platform.isIOS || !await start()) return null;
    return FirebaseMessaging.instance.getAPNSToken();
  }

  @override
  Future<void> deleteToken() async {
    if (!await start()) return;
    await FirebaseMessaging.instance.deleteToken();
  }

  @override
  Stream<String> get tokenRefreshes async* {
    if (!await start()) return;
    yield* FirebaseMessaging.instance.onTokenRefresh;
  }

  @override
  Stream<PushTap> get taps async* {
    if (!await start()) return;
    yield* FirebaseMessaging.onMessageOpenedApp.map(
      (message) => PushTap.fromData(message.data),
    );
  }

  @override
  Future<PushTap?> initialTap() async {
    if (!await start()) return null;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : PushTap.fromData(message.data);
  }

  @override
  Stream<PushForegroundMessage> get foreground async* {
    if (!await start()) return;
    yield* FirebaseMessaging.onMessage
        .where((message) => message.notification != null)
        .map(
          (message) => PushForegroundMessage(
            title: message.notification?.title ?? '',
            body: message.notification?.body ?? '',
            tap: PushTap.fromData(message.data),
          ),
        );
  }
}
