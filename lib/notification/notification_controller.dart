import 'dart:isolate';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class NotificationController {
  static ReceivedAction? initialAction;
  static ReceivePort? receivePort;

  /// Initialize local notifications
  static Future<void> initializeLocalNotifications() async {
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
        )
      ],
      debug: true,
    );

    // Retrieve the initial notification action, if any
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);

    await startListeningNotificationEvents();
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
    );
  }

  /// When a notification is created, increment the notification count
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    final logger = Logger();
    logger.d("Notification created: ${receivedNotification.id}");

    await _increaseNotificationCount();
  }

  /// When a notification is interacted with, decrease the notification count
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    final logger = Logger();

    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      logger.d(
          'Message sent via notification input: "${receivedAction.buttonKeyInput}"');
      await executeLongTaskInBackground();
    } else {
      if (receivePort == null) {
        SendPort? sendPort =
            IsolateNameServer.lookupPortByName('notification_action_port');

        if (sendPort != null) {
          sendPort.send(receivedAction);
          return;
        }
      }

      // Decrease notification count when the user interacts with the notification
      await _decreaseNotificationCount();
      return onActionReceivedImplementationMethod(receivedAction);
    }
  }

  static Future<void> onActionReceivedImplementationMethod(
      ReceivedAction receivedAction) async {
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/notification-page',
      (route) => route.isFirst,
      arguments: receivedAction,
    );
  }

  static Future<void> executeLongTaskInBackground() async {
    await Future.delayed(const Duration(seconds: 4));
    Logger().d("Long background task completed");
  }

  /// Helper method to increase the notification count in SharedPreferences
  static Future<void> _increaseNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('notificationCount') ?? 0;
    currentCount++;
    await prefs.setInt('notificationCount', currentCount);
  }

  /// Helper method to decrease the notification count in SharedPreferences
  static Future<void> _decreaseNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('notificationCount') ?? 0;
    if (currentCount > 0) {
      currentCount--;
      await prefs.setInt('notificationCount', currentCount);
    }
  }
}
