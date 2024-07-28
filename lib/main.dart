import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:craftedclimate/loginscreen/loginscreen.dart';
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
    print("Calling _checkInternetConnection...");
    _hasInternet = _checkInternetConnection().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print(
            "Timeout: No response from _checkInternetConnection within 10 seconds.");
        return false; // Treat as no internet connection on timeout
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    print("Executing _checkInternetConnection...");
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Internet connection available');
        return true; // Internet connection is available
      } else {
        print('No internet connection found');
        return false; // No internet connection
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      return false; // No internet connection
    } catch (e) {
      print('Error: $e');
      return false; // Handle other errors
    }
  }
}
