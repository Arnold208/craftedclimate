import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:craftedclimate/notification/notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../main.dart';

class NotificationService {
  static const String isolateName = 'awesome_notification_isolate';

  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Set up notification action listener
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );

    // Set up background isolate
    IsolateNameServer.registerPortWithName(
      ReceivePort().sendPort,
      isolateName,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(isolateName);
    if (sendPort != null) {
      sendPort.send(receivedAction.toMap());
    } else {
      // If we're in the main isolate, navigate directly
      navigateToNotificationScreen();
    }
  }

  static void showNotification(RemoteMessage message) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: message.notification?.title ?? 'Default Title',
        body: message.notification?.body ?? 'Default Body',
        notificationLayout: NotificationLayout.Default,
        payload: message.data.map((key, value) => MapEntry(key, value.toString())),
      ),
    );
  }

  static void navigateToNotificationScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(MyApp.navigatorKey.currentContext!).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    });
  }
}
