import 'dart:async';
import 'dart:io'; // Required to detect the platform
import 'package:craftedclimate/sideMenu/map/location_class.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  List<DeviceLocation> deviceLocations = [];
  Set<Marker> _markers = {};
    final TextEditingController _searchController = TextEditingController();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(5.6467, -0.1669),  // Default to Accra coordinates
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _fetchAndDisplayDeviceLocations();
  }

  Future<void> _fetchAndDisplayDeviceLocations() async {
    try {
      final locations = await fetchDeviceLocations();
      setState(() {
        deviceLocations = locations;
        _markers = locations.map((location) {
          return Marker(
            markerId: MarkerId(location.auid),
            position: LatLng(location.location.latitude, location.location.longitude),
            infoWindow: InfoWindow(
              title: 'Device: ${location.auid}',
              snippet: 'Battery: ${location.battery}%',
            ),
            icon: location.status == Status.ONLINE
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onTap: () {
              _showDeviceDetails(location);
            },
          );
        }).toSet();
      });
    } catch (e) {
      // Handle error
      print('Error fetching device locations: $e');
    }
  }

  Future<List<DeviceLocation>> fetchDeviceLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final response = await http.get(
      Uri.parse('https://cctelemetry-dev.azurewebsites.net/user/$userId/device-locations'),
    );

    if (response.statusCode == 200) {
      return deviceLocationFromJson(response.body);
    } else {
      throw Exception('Failed to load device locations');
    }
  }

  void _showDeviceDetails(DeviceLocation location) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Device: ${location.auid}'),
            content: Column(
              children: [
                const SizedBox(height: 10),
                Text('Country: ${location.location.country}'),
                Text('Region: ${location.location.region}'),
                Text('City: ${location.location.city}'),
                Text('Street: ${location.location.street}'),
                Text('Battery: ${location.battery}%'),
                Text('Status: ${location.status == Status.ONLINE ? 'Online' : 'Offline'}'),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Device: ${location.auid}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Country: ${location.location.country}'),
                Text('Region: ${location.location.region}'),
                Text('City: ${location.location.city}'),
                Text('Street: ${location.location.street}'),
                Text('Battery: ${location.battery}%'),
                Text('Status: ${location.status == Status.ONLINE ? 'Online' : 'Offline'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _searchDevice(String query) {
    final filteredLocations = deviceLocations.where((location) {
      return location.auid.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _markers = filteredLocations.map((location) {
        return Marker(
          markerId: MarkerId(location.auid),
          position: LatLng(location.location.latitude, location.location.longitude),
          infoWindow: InfoWindow(
            title: 'Device: ${location.auid}',
            snippet: 'Battery: ${location.battery}%',
          ),
          icon: location.status == Status.ONLINE
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _showDeviceDetails(location);
          },
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAndDisplayDeviceLocations,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchDevice,
                  decoration: const InputDecoration(
                    hintText: 'Search for a device by AUID',
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
