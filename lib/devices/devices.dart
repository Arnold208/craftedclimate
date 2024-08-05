import 'dart:convert';
import 'package:craftedclimate/aqi/aqi_gauge.dart';
import 'package:craftedclimate/graph/custom_graph.dart';
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
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";

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
          '$baseUrl/telemetry-user/${widget.device['deviceId']}?userid=$userId&limit=1';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.device['name'],
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w400,
              color: Colors.green,
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings or handle settings action
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
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
                      const SizedBox(height: 1),

                      // Device AUID, location, and status row with placeholders and values underneath
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green, // Green border color
                            width: 2, // Border width
                          ),
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        padding: const EdgeInsets.all(
                            8), // Padding inside the container
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn(
                              'AUID',
                              widget.device['deviceId'],
                              alignLabelLeft:
                                  true, // Shift the label to the left
                            ),
                            _buildInfoColumn(
                              'LOCATION',
                              truncateWithEllipsis(8, location['city']),
                              icon: Icons.public,
                              alignLabelLeft:
                                  true, // Shift the label to the left
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
                              alignLabelLeft:
                                  true, // Shift the label to the left
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      // AQI Gauge
                      if (dataPoints != null && dataPoints!['aqi'] != null)
                        Center(
                          child: AQIGauge(
                              aqi: (dataPoints!['aqi'] as num).toDouble()),
                        ),
                      Center(
                        child: Text(
                          timestamp ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TELEMETRY',
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      const SizedBox(height: 16),
                      if (dataPoints != null) ...[
                        // First 4 Environment metrics cards using GridView
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Two cards per row
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            childAspectRatio: 1.0, // Aspect ratio of each card
                          ),
                          itemCount: dataPoints!.length
                              .clamp(0, 4), // Limit to the first 4 items
                          itemBuilder: (context, index) {
                            final key = dataPoints!.keys.elementAt(index);
                            final value = dataPoints![key];

                            // Skip these fields
                            if (key == 'auid' || key == 'date') {
                              return const SizedBox.shrink();
                            }

                            return _buildMetricCard(
                              _formatMetricName(key),
                              _formatMetricValue(value),
                              _getMetricIcon(key),
                            );
                          },
                        ),
                        // Expansion tile for more data
                        if (dataPoints!.length > 4)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              childrenPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              title: const Text(
                                'More Data',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              children: [
                                // Correctly use GridView to avoid large space
                                GridView.builder(
                                  shrinkWrap: true,
                                  padding:
                                      const EdgeInsets.all(0), // Remove padding
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // Two cards per row
                                    mainAxisSpacing: 16.0,
                                    crossAxisSpacing: 16.0,
                                    childAspectRatio:
                                        1.0, // Aspect ratio of each card
                                  ),
                                  itemCount: dataPoints!.length - 4,
                                  itemBuilder: (context, index) {
                                    final key =
                                        dataPoints!.keys.elementAt(index + 4);
                                    final value = dataPoints![key];

                                    if (key == 'auid' || key == 'date') {
                                      return const SizedBox.shrink();
                                    }

                                    return _buildMetricCard(
                                      _formatMetricName(key),
                                      _formatMetricValue(value),
                                      _getMetricIcon(key),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ] else ...[
                        const Center(
                          child: Text(
                            'No telemetry from sensor',
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w400,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // History title
                      const Text(
                        'HISTORY',
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      // Graph Integration
                      // Use SizedBox to give the graph a specific height
                      SizedBox(
                        height: 400,
                        // width: 600, // Adjust the height as needed
                        child: SensorGraphWidget(
                          auid: widget.device['deviceId'],
                          base: "https://cctelemetry-dev.azurewebsites.net/",
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
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

  // Function to truncate text with ellipsis
  String truncateWithEllipsis(int cutoff, String text) {
    return (text.length <= cutoff) ? text : '${text.substring(0, cutoff)}...';
  }

  Widget _buildInfoColumn(String label, String value,
      {IconData? icon, Color? statusColor, bool alignLabelLeft = false}) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: alignLabelLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: statusColor ?? const Color.fromARGB(255, 42, 125, 180),
                ),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onTap: () {
                  // Show a dialog with the full text when the text is tapped
                  _showFullTextDialog(context, value);
                },
                child: Text(
                  truncateWithEllipsis(10, value), // Truncated text
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: statusColor ?? Color.fromARGB(255, 0, 0, 0),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Function to show a dialog with the full text
  void _showFullTextDialog(BuildContext context, String fullText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              // Max width set to 80% of the screen width
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              // Max height set to 30% of the screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w400,
                  color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
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
          style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w300,
              color: Colors.black),
        ),
      ),
    );
  }
}
