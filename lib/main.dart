import 'package:craftedclimate/CLONE/auth_service.dart';
import 'package:craftedclimate/CLONE/connectivity_service.dart';
import 'package:craftedclimate/CLONE/firebase_service.dart';
import 'package:craftedclimate/CLONE/notification_service.dart';
import 'package:craftedclimate/CLONE/permission_service.dart';
import 'package:craftedclimate/homescreen/homescreen.dart';
import 'package:craftedclimate/loginscreen/loginscreen.dart';
import 'package:craftedclimate/notification/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  await NotificationService.initializeNotifications();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFEFEFEF)),
      debugShowCheckedModeBanner: false,
      home: const Initializer(),
      routes: {
        '/notification-page': (context) => const NotificationScreen(),
      },
    );
  }
}

class Initializer extends StatefulWidget {
  const Initializer({super.key});

  @override
  InitializerState createState() => InitializerState();
}

class InitializerState extends State<Initializer> {
  late Future<bool> _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    _isLoggedIn = ConnectivityService.checkInternetConnection().then(
      (hasInternet) async {
        if (hasInternet) {
          await PermissionService.requestAllPermissions();
          await NotificationService.initializeNotifications();
          return await AuthService.checkIfLoggedIn();
        }
        return false;
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data == true) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
