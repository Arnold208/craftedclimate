import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert'; // For encoding the JSON

class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<List<ScanResult>> scannedDevices = ValueNotifier([]);
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isScanning = false;
  bool isDone = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Faster pulse
    );

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    FlutterBluePlus.adapterState.listen((state) {
      setState(() {});
    });
  }

  Future<void> _checkBluetoothAndStartScan() async {
    var state = await FlutterBluePlus.adapterState.first;
    if (state == BluetoothAdapterState.off) {
      bool? turnOn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Bluetooth is off",
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w300,
                  color: Color.fromARGB(255, 2, 133, 239))),
          content: const Text("Bluetooth is off. Do you want to turn it on?",
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w300,
                  color: Color.fromARGB(255, 2, 133, 239))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel",
                  style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w300,
                      color: Color.fromARGB(255, 2, 133, 239))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Turn On",
                  style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w300,
                      color: Color.fromARGB(255, 2, 133, 239))),
            ),
          ],
        ),
      );

      if (turnOn == true) {
        await FlutterBluePlus.turnOn();
        _startScan();
      }
    } else if (state == BluetoothAdapterState.on) {
      _startScan();
    }
  }

  Future<void> _startScan() async {
    if (!isScanning) {
      setState(() {
        isScanning = true;
        isDone = false;
      });
      scannedDevices.value.clear();
      _animationController.repeat(reverse: true);

      FlutterBluePlus.startScan(timeout: const Duration(seconds: 60));
      FlutterBluePlus.scanResults.listen((results) {
        final filteredResults = results.where((result) => result
            .advertisementData.serviceUuids
            .any((uuid) => uuid.toString().startsWith(
                "4fafc201"))); // Replace with your specific UUID prefix
        scannedDevices.value = filteredResults.toList();
      }).onDone(() {
        _stopScan();
      });
    }
  }

  void _stopScan() {
    setState(() {
      isScanning = false;
      isDone = true;
    });
    _animationController.stop();
    FlutterBluePlus.stopScan();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Connection successful!",
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 253, 254, 255)))),
        );
      }

      // After connecting, discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find the service and characteristic to read the message
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.read) {
            var value = await characteristic.read();
            String message = String.fromCharCodes(value);

            if (message == "HomeSense") {
              // Show dialog for SSID and password
              _showWifiDialog(device);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Message from device: $message",
                      style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 253, 254, 255))),
                ),
              );
            }
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Connection failed: $e",
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 2, 133, 239)))),
        );
      }
    }
  }

  void _showWifiDialog(BluetoothDevice device) {
    final TextEditingController ssidController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter WiFi Details",
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: 'SSID',
                hintText: 'Enter WiFi SSID',
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter WiFi Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel",
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 2, 133, 239))),
          ),
          ElevatedButton(
            onPressed: () {
              final String ssid = ssidController.text;
              final String password = passwordController.text;

              if (ssid.isNotEmpty && password.isNotEmpty) {
                // Create the JSON object
                final jsonString = jsonEncode({
                  'ssid': ssid,
                  'password': password,
                });

                // Send the JSON to the device
                _sendWifiCredentials(device, jsonString);
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 3, 47, 113),
            ),
            child: const Text("Send",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWifiCredentials(
      BluetoothDevice device, String jsonString) async {
    // Find the characteristic to write the WiFi credentials to
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          await characteristic.write(utf8.encode(jsonString));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("WiFi credentials sent!",
                    style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 253, 254, 255)))),
          );
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                  isScanning
                      ? "SEARCHING..."
                      : isDone
                          ? "DONE"
                          : "",
                  style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 0, 0, 0))),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: _checkBluetoothAndStartScan,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isScanning) ...[
                    ScaleTransition(
                      scale: _animation,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 92, 188, 248)
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Color.fromARGB(255, 82, 114, 255).withOpacity(0.2),
                      ),
                    ),
                  ],
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromARGB(255, 7, 38, 190),
                    ),
                    child: const Icon(
                      Icons.bluetooth,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<List<ScanResult>>(
              valueListenable: scannedDevices,
              builder: (context, devices, child) {
                return Column(
                  children: [
                    if (isScanning)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("Scanning for devices...",
                            style: TextStyle(
                                fontSize: 17,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 0, 0, 0))),
                      ),
                    if (devices.isNotEmpty) ...[
                      ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index].device;
                          return Card(
                            color: Colors.green,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              leading: const Icon(Icons.sensors,
                                  size: 28, color: Colors.white),
                              title: Text(
                                  device.name.isNotEmpty
                                      ? device.name
                                      : "Unknown Device",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Raleway',
                                      fontWeight: FontWeight.w400,
                                      color:
                                          Color.fromARGB(255, 255, 255, 255))),
                              subtitle: Text(
                                device.id.toString(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                                color: Colors.white,
                              ),
                              onTap: () => _connectToDevice(device),
                            ),
                          );
                        },
                      ),
                    ],
                    if (!isScanning && devices.isEmpty) ...[
                      const SizedBox(height: 20),
                      const Text("No devices found",
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w300,
                              color: Color.fromARGB(255, 0, 0, 0))),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _checkBluetoothAndStartScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 3, 47, 113),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                        ),
                        child: const Text(
                          "Rescan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
