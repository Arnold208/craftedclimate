import 'package:flutter/material.dart';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 65, 161, 70),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options action
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80, // Large icon size for emphasis
              color: Color.fromARGB(255, 3, 55, 132),
            ),
            SizedBox(height: 20), // Spacing between icon and text
            Text(
              "Edit and Configure your App",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
