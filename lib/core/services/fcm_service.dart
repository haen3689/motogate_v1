import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'motogate_channel',
    'AutoPass',
    description: 'ແຈ້ງເຕືອນຈາກ AutoPass',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    // ขอ permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // สร้าง notification channel (Android)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Foreground notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // FCM token ຖືກສົ່ງຫາ Rails API ຫຼັງ login ສຳເລັດ (ໃນ otp_screen.dart)
  }

  static Future<String?> getToken() => _messaging.getToken();

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
