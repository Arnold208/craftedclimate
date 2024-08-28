import 'package:flutter/material.dart';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  bool notificationsEnabled = true;
  bool locationEnabled = true;

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
              fontSize: 15,
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
              const ListTile(
                leading: const CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                      "https://craftedclimateota.blob.core.windows.net/images/carfted%20climateArtboard%201.jpg?sp=r&st=2024-07-27T23:28:52Z&se=2025-08-30T07:28:52Z&sv=2022-11-02&sr=b&sig=eQYmFouIWVpJ9xfNm5WTKrIBqtG2vmKYrgait2TFZas%3D"),
                ),
                title: Text('Jack Reacher',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
                subtitle: Text(
                  'geniusben@gmail.com',
                  style: TextStyle(fontSize: 13),
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
                _buildSwitchTile('Notificatin', Icons.notifications_none,
                    notificationsEnabled, (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
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
                _buildListTile('Friend Sugession', Icons.person_add_outlined),
                _buildListTile('Help', Icons.help_outline),
              ]),
            ],
          ),
        ));
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
