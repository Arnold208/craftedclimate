import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:isolate';
import 'dart:ui';
import 'notification_service.dart';
import '../firebase_options.dart';


// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // You can handle the background message here, e.g., show a notification
  NotificationService.showNotification(message);
}

class FirebaseService {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseService._setupFirebaseMessaging();
  }


  static Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    String? token = await messaging.getToken();
    print('FCM Device Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService.showNotification(message);
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification when the app is opened from the background
      NotificationService.navigateToNotificationScreen();
    });

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Handle the initial message when the app is launched from a notification
      NotificationService.navigateToNotificationScreen();
    }

    // Listen for background/terminated notifications
    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(
        port.sendPort, NotificationService.isolateName);
    port.listen((dynamic data) {
      // Navigate when we receive a message from the isolate
      NotificationService.navigateToNotificationScreen();
    });
  }

  
}
