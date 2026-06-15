import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  late final FirebaseMessaging _fcm;
  String? _token;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel_v2', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  /// Initializes Firebase and registers push notification listeners
  Future<void> initialize() async {
    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      debugPrint('🔥 Firebase initialized successfully!');

      // 2. Request Notification Permission (iOS & Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('🔔 Notification Permission Status: ${settings.authorizationStatus}');

      // 3. Initialize Flutter Local Notifications for Foreground Presentation
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(settings: initializationSettings);

      // Create high importance channel
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      
      // Explicitly request permissions on Android 13+
      await androidPlugin?.requestNotificationsPermission();

      // 4. Get the FCM Token
      _token = await _fcm.getToken();
      debugPrint('🔑 FCM Device Token: $_token');

      // 5. Token Refresh Listener — update database when token changes
      _fcm.onTokenRefresh.listen((newToken) {
        _token = newToken;
        debugPrint('🔑 FCM Token Refreshed: $newToken');
        _uploadToken();
      });

      // 6. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground Message Received: ${message.notification?.title}');
        
        final notification = message.notification;

        if (notification != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // 6. App Opened from Background Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📩 App opened from background push notification: ${message.data}');
      });

      // 7. Initial message when app launched from completely killed state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📩 App launched from cold push notification: ${initialMessage.data}');
      }

      // 8. Upload token immediately if user is already logged in
      await _uploadToken();
    } catch (e) {
      debugPrint('❌ PushNotificationService initialization failed: $e');
    }
  }

  /// Uploads or updates the current FCM token in Supabase
  Future<void> _uploadToken() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null || _token == null) {
      debugPrint('⚠️ Cannot upload token: User logged in: ${user != null}, Token exists: ${_token != null}');
      return;
    }

    try {
      final deviceType = Platform.isIOS ? 'ios' : 'android';

      // Upsert the token to the database
      await supabase.from('user_push_tokens').upsert({
        'user_id': user.id,
        'token': _token!,
        'device_type': deviceType,
      }, onConflict: 'token');

      debugPrint('✅ FCM Token securely uploaded to Supabase for user: ${user.id}');
    } catch (e) {
      debugPrint('❌ Failed to upload FCM token to Supabase: $e');
      debugPrint('👉 Make sure you have created the "user_push_tokens" table in your Supabase SQL Editor!');
    }
  }

  /// Triggered on successful user authentication / login
  Future<void> onUserLogin() async {
    debugPrint('🔄 User authenticated. Syncing Push Token...');
    // Refresh token in case it was updated or requested anew
    _token = await _fcm.getToken();
    await _uploadToken();
  }

  /// Triggered on user logout to remove active push association
  Future<void> onUserLogout() async {
    final supabase = Supabase.instance.client;
    if (_token == null) return;

    try {
      // Delete from Supabase so this device stops receiving pushes for this user
      await supabase
          .from('user_push_tokens')
          .delete()
          .eq('token', _token!);
          
      debugPrint('🗑️ FCM Token association removed from Supabase');
    } catch (e) {
      debugPrint('❌ Failed to remove FCM token from Supabase: $e');
    }
  }

  /// Obtains an OAuth2 Access Token from Google APIs using Service Account Credentials.
  Future<String?> _getOAuth2Token() async {
    final clientEmail = dotenv.env['FIREBASE_CLIENT_EMAIL'] ?? '';
    final privateKey = dotenv.env['FIREBASE_PRIVATE_KEY'] ?? '';

    if (clientEmail.isEmpty || privateKey.isEmpty) {
      debugPrint('⚠️ Cannot send Push: Missing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY in .env!');
      return null;
    }

    try {
      // Unescape the private key newline characters if present
      final formattedPrivateKey = privateKey.replaceAll(r'\n', '\n');

      final accountCredentials = ServiceAccountCredentials(
        clientEmail,
        ClientId(clientEmail),
        formattedPrivateKey,
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('❌ Failed to retrieve Google OAuth2 token: $e');
      return null;
    }
  }

  /// Sends a real system push notification to a specific user by their Supabase User ID.
  /// Pulls the user's active device tokens from Supabase, then dispatches the FCM HTTP v1 post.
  Future<void> sendPushNotification({
    required String recipientUserId,
    required String title,
    required String body,
  }) async {
    final supabase = Supabase.instance.client;
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

    if (projectId.isEmpty) {
      debugPrint('⚠️ Cannot send Push Notification: FIREBASE_PROJECT_ID is missing in your .env file!');
      return;
    }

    try {
      // 1. Fetch recipient's active device tokens
      final response = await supabase
          .from('user_push_tokens')
          .select('token')
          .eq('user_id', recipientUserId);

      final tokens = (response as List).map((e) => e['token'] as String).toList();
      if (tokens.isEmpty) {
        debugPrint('ℹ️ No registered push tokens found for recipient user: $recipientUserId');
        return;
      }

      // 2. Generate Google OAuth2 Token asynchronously
      final accessToken = await _getOAuth2Token();
      if (accessToken == null) {
        debugPrint('⚠️ Aborting push dispatch: Could not authorize Google OAuth2.');
        return;
      }

      final dio = Dio();
      final fcmUrl = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      for (final token in tokens) {
        try {
          await dio.post(
            fcmUrl,
            data: {
              'message': {
                'token': token,
                'notification': {
                  'title': title,
                  'body': body,
                },
                'android': {
                  'notification': {
                    'channel_id': 'high_importance_channel_v2',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
                'data': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'type': 'booking',
                },
              }
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            ),
          );
          debugPrint('🚀 Successfully sent system push notification (HTTP v1) to device token: $token');
        } catch (e) {
          debugPrint('❌ Failed to dispatch HTTP v1 push to token $token: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error querying recipient push tokens: $e');
    }
  }
}
