import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  bool notificationsEnabled = true;
  bool locationEnabled = true;

  String username = '';
  String email = '';
  String userId = ''; // Store userId

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data from SharedPreferences
  }

  // Load username, email, userId, and notification state from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Username';
      email = prefs.getString('email') ?? 'Email';
      userId = prefs.getString('userId') ?? ''; // Get the userId
      notificationsEnabled = prefs.getBool('notificationsEnabled') ??
          true; // Load notification state
    });
  }

  // Save notification state to SharedPreferences and send it to the API
  Future<void> _toggleNotification(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    // Send the state to the API
    _sendNotificationStateToServer(value);
  }

  // Send the notification toggle state to the server
  Future<void> _sendNotificationStateToServer(bool notify) async {
    final url = 'https://cctelemetry-dev.azurewebsites.net/toggleNotification';
    final headers = {"Content-Type": "application/json"};

    final body = jsonEncode({
      "userId": userId,
      "notify": notify,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully sent the notification state
        print('Notification state updated on the server');
      } else {
        // Handle error
        print('Failed to update notification state: ${response.body}');
      }
    } catch (error) {
      // Handle network error
      print('Error sending notification state: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(241, 255, 255, 255),
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
            )),
        elevation: 0,
        backgroundColor: const Color.fromARGB(241, 255, 255, 255),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 65, 161, 70),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://craftedclimateota.blob.core.windows.net/images/carfted%20climateArtboard%201.jpg?sp=r&st=2024-07-27T23:28:52Z&se=2025-08-30T07:28:52Z&sv=2022-11-02&sr=b&sig=eQYmFouIWVpJ9xfNm5WTKrIBqtG2vmKYrgait2TFZas%3D"),
              ),
              title: Text(username,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w400)),
              subtitle: Text(
                email,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            _buildSection('Accounts', [
              _buildListTile('Personal Info', Icons.person_outline),
              _buildListTile('Language', Icons.language),
              _buildListTile('Accessibility', Icons.accessibility),
            ]),
            _buildSection('Privacy & Security', [
              _buildListTile('Manage information', Icons.manage_accounts),
              _buildListTile('Password', Icons.lock_outline),
              _buildSwitchTile('Notification', Icons.notifications_none,
                  notificationsEnabled, (value) {
                _toggleNotification(
                    value); // Toggle notification and send request
              }),
            ]),
            _buildSection('Permission', [
              _buildSwitchTile(
                  'Location', Icons.location_on_outlined, locationEnabled,
                  (value) {
                setState(() {
                  locationEnabled = value;
                });
              }),
              _buildListTile('Friend Suggestion', Icons.person_add_outlined),
              _buildListTile('Help', Icons.help_outline),
            ]),
          ],
        ),
      ),
    );
  }
}

Widget _buildSection(String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: children,
        ),
      ),
    ],
  );
}

Widget _buildListTile(String title, IconData icon) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      // Handle tap
    },
  );
}

Widget _buildSwitchTile(
    String title, IconData icon, bool value, Function(bool) onChanged) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
    ),
  );
}
