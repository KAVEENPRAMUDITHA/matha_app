import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. අවසර ඉල්ලීම
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // 2. Token එක ලබා ගැනීම
    String? token = await _messaging.getToken();
    
    // මෙය ඉතා වැදගත්! මෙම Token එක Copy කර තබා ගන්න.
    print("========= DEVICE TOKEN =========");
    print(token);
    print("================================");
  }
}