import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:math';

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
            .any((uuid) => uuid.toString().startsWith("4fafc201")));
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
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection successful!")),
      );
      }

      // Delay for a short while before redirecting to the main page
      await Future.delayed(const Duration(seconds: 2));

      if(mounted)Navigator.pop(context); // Navigate back to the main page
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed: $e")),
      );
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
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: _startScan,
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
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    Positioned.fill(
                      child: ValueListenableBuilder<List<ScanResult>>(
                        valueListenable: scannedDevices,
                        builder: (context, devices, child) {
                          return Stack(
                            children: List.generate(devices.length, (index) {
                              final angle = (2 * pi * index) / devices.length;
                              final offset = Offset(
                                125 * cos(angle),
                                125 * sin(angle),
                              );

                              return Transform.translate(
                                offset: offset,
                                child: GestureDetector(
                                  onTap: () =>
                                      _connectToDevice(devices[index].device),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.devices,
                                        color: Colors.black,
                                        size: 24, // Increased icon size
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        devices[index].device.platformName.isNotEmpty
                                            ? devices[index].device.platformName
                                            : "Unknown Device",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18, // Increased font size
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                  if (!isScanning && isDone) ...[
                    ElevatedButton(
                      onPressed: _startScan,
                      child: const Text("Rescan"),
                    ),
                  ],
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
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
          if (isDone) ...[
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<List<ScanResult>>(
                valueListenable: scannedDevices,
                builder: (context, devices, child) {
                  return Column(
                    children: devices.map((device) {
                      return ListTile(
                        leading: const Icon(Icons.devices, size: 24),
                        title: Text(
                          device.device.platformName.isNotEmpty
                              ? device.device.platformName
                              : "Unknown Device",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        onTap: () => _connectToDevice(device.device),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
