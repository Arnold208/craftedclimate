import 'dart:convert';
import 'package:craftedclimate/devices/devices.dart';
import 'package:craftedclimate/devices/solosense/solosense.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:craftedclimate/bluetooth/bluetooth_scan.dart';
import 'package:craftedclimate/notification/notification.dart';
import 'package:craftedclimate/qr_scan/qr_scan.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SenseCAP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  bool _isMenuVisible = false;
  List<String> _categories = ['All'];
  List<Map<String, dynamic>> _allDevices = [];
  List<Map<String, dynamic>> _filteredDevices = [];
  final List<String> imgList = [
    'https://craftedclimateota.blob.core.windows.net/images/carfted%20climateArtboard%201.jpg?sp=r&st=2024-07-27T23:28:52Z&se=2025-08-30T07:28:52Z&sv=2022-11-02&sr=b&sig=eQYmFouIWVpJ9xfNm5WTKrIBqtG2vmKYrgait2TFZas%3D',
    'https://craftedclimateota.blob.core.windows.net/images/carfted%20climateArtboard%2010.jpg?sp=r&st=2024-07-27T23:32:39Z&se=2025-02-08T07:32:39Z&sv=2022-11-02&sr=b&sig=Rm2GROB3cQR%2FZIWVKatj2xoyh1%2FyvxNRYqglfbt6s0Q%3D',
    'https://craftedclimateota.blob.core.windows.net/images/carfted%20climateArtboard%202.jpg?sp=r&st=2024-07-27T23:35:02Z&se=2025-03-28T07:35:02Z&sv=2022-11-02&sr=b&sig=vvH6kzgpl1JiYfji0fsXgXGeR9BCJh61MvQ0phlEecs%3D',
    'https://craftedclimateota.blob.core.windows.net/images/carfted%20climateArtboard%203.jpg?sp=r&st=2024-07-27T23:35:45Z&se=2025-04-30T07:35:45Z&sv=2022-11-02&sr=b&sig=PQKu%2BxSWVUAFNUV8JCam3DNMY38NWGFw4%2Fo1JSwLx%2Fw%3D'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final url =
          'https://cctelemetry-dev.azurewebsites.net/users/$userId/deployments';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> deployments = jsonResponse['deployments'];

        List<Map<String, dynamic>> allDevices = [];

        for (var deployment in deployments) {
          for (var deviceId in deployment['devices']) {
            final deviceUrl =
                'https://cctelemetry-dev.azurewebsites.net/find-registered-device/$deviceId';
            final deviceResponse = await http.get(Uri.parse(deviceUrl));

            if (deviceResponse.statusCode == 200) {
              final deviceDetails = json.decode(deviceResponse.body);
              allDevices.add({
                'name': deviceDetails['nickname'],
                'deployment': deployment['name'],
                'deviceId': deviceDetails['auid'],
                'status': deviceDetails['status'],
                'battery': deviceDetails['battery'],
                'image': deviceDetails['image'],
                'model': deviceDetails['model'],
                'location': deviceDetails['location']
              });
            } else {
              print(
                  'Error fetching device details: ${deviceResponse.statusCode}');
            }
          }
        }

        setState(() {
          _categories =
              ['All'] + deployments.map((e) => e['name'] as String).toList();
          _allDevices = allDevices;
          _filteredDevices = _allDevices; // Initially show all devices
        });
      } else {
        // Handle error
        print('Error fetching deployments: ${response.statusCode}');
      }
    } else {
      // Handle missing userId
      print('User ID not found');
    }
  }

  Future<void> _refreshCategories() async {
    await _fetchCategories();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredDevices = category == 'All'
          ? _allDevices
          : _allDevices
              .where((device) => device['deployment'] == category)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int onlineCount =
        _filteredDevices.where((device) => device['status'] == 'online').length;
    int offlineCount =
        _filteredDevices.where((device) => device['status'] != 'online').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sense Platform',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 65, 161, 70),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.circle_notifications,
                    size: 25,
                    color: Color.fromARGB(166, 63, 146, 66),
                  ),
                ),
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '7',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.green,
              ),
            ),
            onPressed: () {
              _showAddDeviceDialog(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshCategories,
            child: Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _categories.map(_categoryChip).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            autoPlay: true,
                            aspectRatio: 2.0,
                            enlargeCenterPage: true,
                            viewportFraction: 0.8,
                          ),
                          items: imgList
                              .map((item) => Container(
                                    child: Center(
                                      child: Image.network(item,
                                          fit: BoxFit.cover, width: 600),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Devices',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                height: 7,
                                width: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$onlineCount online',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w300,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 7,
                                width: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$offlineCount offline',
                                style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GridView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _filteredDevices.length,
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(_filteredDevices[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: _isMenuVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedSlide(
                    offset: _isMenuVisible ? Offset.zero : const Offset(1, 0),
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: FloatingActionButton(
                            heroTag: "btn1",
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              // Handle scan QR code action
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.device_hub),
                                SizedBox(height: 2),
                                Text("Hub", textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: FloatingActionButton(
                            heroTag: "btn2",
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              // Handle scan QR code action
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event),
                                SizedBox(height: 2),
                                Text("Events", textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: FloatingActionButton(
                            heroTag: "btn3",
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              // Handle scan QR code action
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person),
                                SizedBox(height: 2),
                                Text("Profile", textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: FloatingActionButton(
                            heroTag: "btn4",
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              // Handle scan QR code action
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.settings),
                                SizedBox(height: 2),
                                Text("Settings", textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "5",
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  onPressed: _toggleMenu,
                  child: Icon(
                    _isMenuVisible ? Icons.close : Icons.menu,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Add Device",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _checkBluetoothPermission(context);
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: const Text(
                        "Bluetooth",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _checkCameraPermission(context);
                      },
                      icon: const Icon(Icons.qr_code),
                      label: const Text(
                        "QR Code",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w300,
            color: isSelected ? Colors.green : const Color.fromARGB(255, 57, 57, 57),
            fontSize: 15),
      ),
      selected: isSelected,
      onSelected: (_) {
        _selectCategory(label);
      },
      backgroundColor: Colors.transparent,
      selectedColor: Colors.transparent,
      checkmarkColor: Colors.green,
      side: isSelected
          ? const BorderSide(color: Colors.green, width: 1)
          : BorderSide.none,
      shape: const StadiumBorder(),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    Color statusColor =
        device['status'] == 'online' ? Colors.green : Colors.red;
    Color batteryColor;

    if (device['battery'] < 30) {
      batteryColor = Colors.red;
    } else if (device['battery'] >= 30 && device['battery'] < 80) {
      batteryColor = Colors.yellow;
    } else {
      batteryColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        if (device['model'] == 'ENV') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailsScreen(device: device),
            ),
          );
        } else if (device['model'] == 'SSM') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => solosenseScreen(device: device),
            ),
          );
        }
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) {
            return _buildCenterDialog(context, device);
          },
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.network(
                  device['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'],
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    device['model'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        device['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.battery_full,
                            color: batteryColor,
                            size: 16,
                          ),
                          Text(
                            '${device['battery']}%',
                            style: TextStyle(
                              color: batteryColor,
                              fontSize: 12,
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterDialog(BuildContext context, Map<String, dynamic> device) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Telemetry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${device['name']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Deployment: ${device['deployment']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Device ID: ${device['deviceId']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkBluetoothPermission(BuildContext context) async {
    await Permission.bluetooth.request();
    var status = await Permission.bluetooth.status;
    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BluetoothConnectScreen()),
      );
    } else if (status.isDenied) {
      if (await Permission.bluetooth.request().isGranted) {
        // Permission granted
      } else {
        _showPermissionDeniedDialog(context, 'Bluetooth');
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _checkCameraPermission(BuildContext context) async {
    await Permission.camera.request();
    var status = await Permission.camera.status;
    if (status.isGranted) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const QRScanner()));
    } else if (status.isDenied) {
      if (await Permission.camera.request().isGranted) {
        // Permission granted
      } else {
        _showPermissionDeniedDialog(context, 'Camera');
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _showPermissionDeniedDialog(BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Permission Denied"),
          content:
              Text("$permission permission is required to use this feature."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
