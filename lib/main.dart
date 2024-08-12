import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:craftedclimate/loginscreen/loginscreen.dart';
import 'package:craftedclimate/utility/no_internet.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:logger/web.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  // WidgetsFlutterBinding
  //     .ensureInitialized(); // Ensure widgets binding is initialized
  // await dotenv.load(fileName: "assets/.env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _hasInternet;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _hasInternet = _checkInternetConnection().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print(
            "Timeout: No response from _checkInternetConnection within 10 seconds.");
        return false; // Treat as no internet connection on timeout
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAwesomeNotifications();
      _showPermissionsDialog();
    });
  }

  // Initialize Awesome Notifications
  void _initializeAwesomeNotifications() {
    AwesomeNotifications().initialize(
      null, // Set the icon to null if you want to use the default app icon
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
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic group',
        ),
      ],
      debug: true,
    );
  }

  // Show a dialog to explain permissions
  void _showPermissionsDialog() {
    logger.i('Permission request dialog displayed');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
              'This app requires access to Bluetooth, Camera, Location, and Notifications to function properly. Please grant these permissions when requested.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    print('Requesting permissions');

    // Request Bluetooth permission (iOS-specific)
    if (Platform.isIOS) {
      if (await Permission.bluetooth.request().isGranted) {
        logger.d('Bluetooth permission granted');
      } else {
        logger.d('Bluetooth permission denied');
      }
    }

    // Request Camera permission
    if (await Permission.camera.request().isGranted) {
      logger.i('Camera permission granted');
    } else {
      logger.i('Camera permission denied');
    }

    // Request Location permission
    if (await Permission.locationWhenInUse.request().isGranted) {
      logger.i('Location permission granted');
    } else {
      logger.i('Location permission denied');
    }

    // Request Notification permission
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications().then((_) {
          logger.i('Notification permission requested');
        });
      } else {
        logger.i('Notification permission already granted');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFEFEFEF)),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _hasInternet,
        builder: (context, snapshot) {
          print(
              "FutureBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data == true) {
              return const LoginScreen(); // Proceed to HomeScreen if connected
            } else if (snapshot.hasError) {
              print('FutureBuilder hasError: ${snapshot.error}');
              return Center(
                child: Text('Error: ${snapshot.error}'),
              ); // Show error message if any error occurs
            } else {
              print('No internet connection detected');
              return const NoInternetScreen(); // Show no internet screen
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    logger.d("Executing _checkInternetConnection...");
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        logger.d('Internet connection available');
        return true; // Internet connection is available
      } else {
        logger.d('No internet connection found');
        return false; // No internet connection
      }
    } on SocketException catch (e) {
      logger.e('SocketException: $e');
      return false; // No internet connection
    } catch (e) {
      logger.e('Error: $e');
      return false; // Handle other errors
    }
  }
}
