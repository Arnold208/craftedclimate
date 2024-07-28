import 'dart:convert';
import 'package:craftedclimate/aqi/aqi_gauge.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceDetailsScreen({required this.device, Key? key}) : super(key: key);

  @override
  _DeviceDetailsScreenState createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  Map<String, dynamic>? dataPoints;
  String? timestamp;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataPoints();
  }

  Future<void> fetchDataPoints() async {
    setState(() {
      isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final url =
          'https://cctelemetry-dev.azurewebsites.net/telemetry-user/${widget.device['deviceId']}?userid=$userId&limit=1';
      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          final data = jsonResponse['data'][0]['data'];

          setState(() {
            timestamp = DateTime.parse(data['date']).toLocal().toString();
            dataPoints = data.isNotEmpty ? data : null;
            isLoading = false;
          });
        } else {
          print('Error fetching data points: ${response.statusCode}');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching data points: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('User ID not found');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse the location JSON string
    final Map<String, dynamic> location = jsonDecode(widget.device['location']);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.device['name'],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 65, 161, 70),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings or handle settings action
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchDataPoints,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Device AUID, location, and status row with placeholders and values underneath
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            'AUID',
                            widget.device['deviceId'],
                          ),
                          _buildInfoColumn(
                            'LOCATION',
                            location['country'] + " - " + location['city'],
                            icon: Icons.public,
                          ),
                          _buildInfoColumn(
                            'STATUS',
                            widget.device['status'],
                            statusColor: widget.device['status'] == 'online'
                                ? Colors.green
                                : Colors.red,
                            icon: widget.device['status'] == 'online'
                                ? Icons.check_circle
                                : Icons.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // AQI Gauge
                      if (dataPoints != null && dataPoints!['aqi'] != null)
                        Center(
                          child: AQIGauge(
                              aqi: (dataPoints!['aqi'] as num).toDouble()),
                        ),
                      const SizedBox(height: 16),

                      Text(
                        'TELEMETRY',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (dataPoints != null) ...[
                        // First 4 Environment metrics cards
                        Wrap(
                          spacing: 42.0,
                          runSpacing: 16.0,
                          children: _buildMetricCards(dataPoints!, limit: 4),
                        ),
                        const SizedBox(height: 16),
                        // Expansion tile for more data
                        if (dataPoints!.length > 4)
                          ExpansionTile(
                            title: Text(
                              'More Data',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            children: [
                              Wrap(
                                spacing: 16.0,
                                runSpacing: 16.0,
                                children:
                                    _buildMetricCards(dataPoints!, skip: 4),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        // Timestamp
                        Center(
                          child: Text(
                            timestamp ?? 'N/A',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ] else ...[
                        const Center(
                          child: Text(
                            'No telemetry from sensor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // History title
                      Text(
                        'HISTORY',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      // Mock graph or chart
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            'Graph or Chart Placeholder',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Day, Week, Month tabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTab('Day'),
                          _buildTab('Week'),
                          _buildTab('Month'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _buildMetricCards(Map<String, dynamic> data,
      {int limit = 0, int skip = 0}) {
    List<Widget> cards = [];
    int index = 0;
    data.forEach((key, value) {
      if (key != 'auid' && key != 'date') {
        if (skip > 0 && index < skip) {
          index++;
          return;
        }
        if (limit > 0 && index >= skip + limit) return;
        cards.add(_buildMetricCard(_formatMetricName(key),
            _formatMetricValue(value), _getMetricIcon(key)));
        index++;
      }
    });
    return cards;
  }

  String _formatMetricName(String key) {
    switch (key) {
      case 'temperature':
        return 'Temperature (°C)';
      case 'pressure':
        return 'Pressure (hPa)';
      case 'humidity':
        return 'Humidity (%)';
      case 'sound':
        return 'Sound (dB)';
      case 'pm1':
        return 'PM1 (µg/m³)';
      case 'pm2':
        return 'PM2.5 (µg/m³)';
      case 'pm10':
        return 'PM10 (µg/m³)';
      case 'lux':
        return 'Lux (lx)';
      case 'battery':
        return 'Battery (V)';
      case 'uv':
        return 'UV (Index)';
      case 'aqi':
        return 'AQI';
      default:
        return key;
    }
  }

  String _formatMetricValue(dynamic value) {
    if (value is num) {
      return value
          .toDouble()
          .toStringAsFixed(2); // Ensure value is cast to double
    }
    return value.toString();
  }

  IconData _getMetricIcon(String key) {
    switch (key) {
      case 'temperature':
        return Icons.thermostat;
      case 'pressure':
        return Icons.speed;
      case 'humidity':
        return Icons.water_damage;
      case 'sound':
        return Icons.volume_up;
      case 'pm1':
      case 'pm2':
      case 'pm10':
        return Icons.air;
      case 'lux':
        return Icons.wb_sunny;
      case 'battery':
        return Icons.battery_full;
      case 'uv':
        return Icons.wb_incandescent;
      case 'aqi':
        return Icons.assessment;
      default:
        return Icons.device_unknown;
    }
  }

  Widget _buildInfoColumn(String label, String value,
      {IconData? icon, Color? statusColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: statusColor ?? Color.fromARGB(255, 42, 125, 180),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor ?? Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    return GestureDetector(
      onTap: () {
        // Handle tab change
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
