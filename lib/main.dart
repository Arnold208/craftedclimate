import 'dart:io';
import 'package:craftedclimate/loginscreen/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:craftedclimate/utility/no-internet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _hasInternet;

  @override
  void initState() {
    super.initState();
    _hasInternet = _checkInternetConnection();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _hasInternet,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              return const LoginScreen(); // Proceed to HomeScreen if connected
            } else {
              return const NoInternetScreen(); // Show no internet screen
            }
          } else {
            return const Center(
                child:
                    CircularProgressIndicator()); // Show loading indicator while checking
          }
        },
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Internet connection is available
      }
    } on SocketException {
      return false; // No internet connection
    }
    return false; // Default to no connection
  }
}
