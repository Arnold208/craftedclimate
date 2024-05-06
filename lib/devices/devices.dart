import 'package:flutter/material.dart';

class DeviceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceDetailsScreen({required this.device, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              device['image'],
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${device['name']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Model: ${device['model']}'),
            const SizedBox(height: 8),
            Text('Status: ${device['status']}'),
            const SizedBox(height: 8),
            Text('Battery: ${device['battery']}%'),
            const SizedBox(height: 8),
            Text('Deployment: ${device['deployment']}'),
            const SizedBox(height: 8),
            Text('AUID: ${device['auid']}'),
          ],
        ),
      ),
    );
  }
}
