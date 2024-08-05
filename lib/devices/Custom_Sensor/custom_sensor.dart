import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomSensor extends StatefulWidget {
  const CustomSensor({super.key});

  @override
  _CustomSensorState createState() => _CustomSensorState();
}

class _CustomSensorState extends State<CustomSensor> {
  late TooltipBehavior _tooltipBehavior;

  // List to store available data points from the response
  List<String> dataPoints = [];

  // Current selected data point
  String? selectedDataPoint;

  // List to store telemetry data
  List<Map<String, dynamic>> telemetryData = [];

  // API endpoint
  final String apiUrl = 'https://cctelemetry-dev.azurewebsites.net/filter-data';

  // Shared Preferences key
  final String cacheKey = 'cachedTelemetryData';

  // Loading state
  bool isLoading = false;

  // Current time range for the request
  String currentTimeRange = "24h"; // Default time range

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    loadCachedTelemetryData(); // Load cached data on initialization
  }

  // Method to fetch telemetry data from the API and cache it
  Future<void> fetchTelemetryData(String timeRange) async {
    setState(() {
      isLoading = true; // Set loading state
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "auid": "23A-765-BD761",
          "userid": "7v7GPWFnQF",
          "timeRange": timeRange,
          "limit": 50
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        // Cache the telemetry data with time range in key
        await prefs.setString(
            '$cacheKey-$timeRange', jsonEncode(jsonResponse['telemetryData']));
        updateTelemetryData(jsonResponse['telemetryData']);
      } else {
        // Handle error
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching telemetry data: $e');
    } finally {
      setState(() {
        isLoading = false; // Reset loading state
      });
    }
  }

  // Load cached telemetry data
  Future<void> loadCachedTelemetryData() async {
    setState(() {
      isLoading = true; // Set loading state
    });

    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('$cacheKey-$currentTimeRange');
    if (cachedData != null) {
      final List<dynamic> jsonData = jsonDecode(cachedData);
      updateTelemetryData(jsonData);
    } else {
      // Fetch data if no cache exists for the selected time range
      await fetchTelemetryData(currentTimeRange);
    }

    setState(() {
      isLoading = false; // Reset loading state
    });
  }

  // Update telemetry data and data points
  void updateTelemetryData(List<dynamic> data) {
    setState(() {
      telemetryData.clear(); // Clear existing data
      telemetryData = List<Map<String, dynamic>>.from(data);
      if (telemetryData.isNotEmpty) {
        // Extract data points from the first telemetry entry
        dataPoints = telemetryData.first.keys
            .where((key) =>
                key != '_id' &&
                key != 'auid' &&
                key != 'error' &&
                key != 'date')
            .toList();
        selectedDataPoint ??= dataPoints.first;
      }
    });
  }

  // Function to parse date string into DateTime object
  DateTime parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  // Function to handle null or invalid data
  double? getValidValue(dynamic value) {
    if (value == null) return null;
    if (value is int || value is double) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Method to handle time range button presses
  void onTimeRangePressed(String timeRange) {
    setState(() {
      currentTimeRange = timeRange; // Update current time range
    });
    loadCachedTelemetryData(); // Load data for the new time range
  }

  @override
  Widget build(BuildContext context) {
    // Determine start and end date
    DateTime? startDate;
    DateTime? endDate;
    if (telemetryData.isNotEmpty) {
      startDate = parseDate(telemetryData.first['date']);
      endDate = parseDate(telemetryData.last['date']);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncfusion IoT Sensor Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await fetchTelemetryData(currentTimeRange);
            }, // Refresh data
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator()) // Show a loading spinner
            : Column(
                children: [
                  // Row for time range buttons

                  const SizedBox(height: 16),
                  // Dropdown for selecting data point
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 2.0), // Adjust padding as needed
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.green[100], // Dropdown background color
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: const Offset(0, 3), // Shadow position
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedDataPoint,
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.black),
                              iconSize: 24,
                              elevation: 16,
                              dropdownColor:
                                  Colors.green[50], // Dropdown menu color
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w300,
                                color: Colors.black,
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedDataPoint = newValue!;
                                  loadCachedTelemetryData();
                                  // Only reload chart with cached data, no API call
                                });
                              },
                              items: dataPoints.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.toUpperCase()),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Container for the chart
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: const Offset(
                                0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: SfCartesianChart(
                        // Set the chart title
                        title: ChartTitle(
                            text:
                                'Graph of $selectedDataPoint over Time\n(${startDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(startDate) : ''} - ${endDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(endDate) : ''})'),
                        // Enable the legend
                        legend: const Legend(isVisible: false),
                        // Use the initialized tooltip behavior
                        tooltipBehavior: _tooltipBehavior,
                        // Configure the X-axis as a DateTime axis
                        primaryXAxis: DateTimeAxis(
                          majorGridLines: const MajorGridLines(width: 0),
                          edgeLabelPlacement: EdgeLabelPlacement.shift,
                          dateFormat:
                              DateFormat("dd/MM/yyyy HH:mm"), // Format the date
                          intervalType: DateTimeIntervalType.auto,
                        ),
                        // Configure Y-axis
                        primaryYAxis: NumericAxis(
                          labelStyle: const TextStyle(
                            color: Colors.black54,
                          ),
                          axisLine: const AxisLine(width: 0),
                          majorTickLines: const MajorTickLines(size: 0),
                          majorGridLines: const MajorGridLines(
                            color: Colors.grey,
                            dashArray: [5, 5],
                          ),
                        ),
                        plotAreaBorderWidth: 0,
                        series: <CartesianSeries<Map<String, dynamic>,
                            DateTime>>[
                          LineSeries<Map<String, dynamic>, DateTime>(
                            dataSource: telemetryData,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                parseDate(data['date']),
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                getValidValue(data[selectedDataPoint]),
                            // Customize the line appearance
                            color: Colors.blueAccent,
                            width: 2,
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                              shape: DataMarkerType.circle,
                              color: Colors.blue,
                              borderWidth: 2,
                              borderColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      buildTimeRangeButton("24h", "24 Hours"),
                      buildTimeRangeButton("week", "Week"),
                      buildTimeRangeButton("month", "Month"),
                      buildTimeRangeButton("year", "Year"),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildTimeRangeButton(String timeRange, String title) {
    return GestureDetector(
      onTap: () => onTimeRangePressed(timeRange),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w300,
              color: Colors.black),
        ),
      ),
    );
  }
}
