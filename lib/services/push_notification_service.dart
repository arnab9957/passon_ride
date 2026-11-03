import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers this device for FCM push notifications and routes taps.
///
/// Pushes are sent server-side by the `send-push` edge function whenever a row
/// is inserted into `notifications`. While the app is open, the in-app bell
/// already updates via realtime, so foreground pushes are not shown again.
///
/// Web needs a VAPID key: build with `--dart-define=FCM_VAPID_KEY=...`.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  String? _token;
  String? _registeredFor;
  bool _handlersAttached = false;
  StreamSubscription<String>? _refreshSub;

  bool get _supported => Firebase.apps.isNotEmpty && (!kIsWeb || _vapidKey.isNotEmpty);

  String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      _ => 'other',
    };
  }

  /// Call once at startup. [onOpen] receives the push `data` when a
  /// notification is tapped (app in background or launched from it).
  Future<void> attachTapHandlers(void Function(Map<String, dynamic> data) onOpen) async {
    if (_handlersAttached || Firebase.apps.isEmpty) return;
    _handlersAttached = true;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(m.data));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) onOpen(initial.data);
    } catch (e) {
      debugPrint('Push tap handlers unavailable: $e');
    }
  }

  /// Ask permission, get the FCM token and store it for [userId].
  Future<void> registerForUser(String userId) async {
    if (!_supported || userId.isEmpty || _registeredFor == userId) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push permission denied');
        return;
      }
      await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);

      _token = await messaging.getToken(vapidKey: kIsWeb ? _vapidKey : null);
      if (_token == null) return;
      await _save(_token!);
      _registeredFor = userId;

      _refreshSub ??= messaging.onTokenRefresh.listen((t) {
        _token = t;
        _save(t);
      });
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Remove this device's token. Call BEFORE signing out (needs the session).
  Future<void> unregister() async {
    final token = _token;
    _registeredFor = null;
    if (token == null) return;
    try {
      await Supabase.instance.client.rpc('unregister_device_token', params: {'p_token': token});
    } catch (e) {
      debugPrint('Push unregister failed: $e');
    }
  }

  Future<void> _save(String token) async {
    try {
      await Supabase.instance.client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': _platform,
      });
    } catch (e) {
      debugPrint('Saving push token failed: $e');
    }
  }
}
