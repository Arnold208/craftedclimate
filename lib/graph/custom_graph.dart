import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SensorGraphWidget extends StatefulWidget {
  final String auid;
  final String base;

  const SensorGraphWidget({
    super.key,
    required this.auid,
    required this.base,
  });

  @override
  _SensorGraphWidgetState createState() => _SensorGraphWidgetState();
}

class _SensorGraphWidgetState extends State<SensorGraphWidget> {
  late TooltipBehavior _tooltipBehavior;

  // List to store available data points from the response
  List<String> dataPoints = [];

  // Current selected data point
  String? selectedDataPoint;

  // List to store telemetry data
  List<Map<String, dynamic>> telemetryData = [];

  // API endpoint and cache key
  static const String cacheKey = 'cachedTelemetryData';

  // Loading state
  bool isLoading = false;

  // Current time range for the request
  String currentTimeRange = '24h'; // Default time range

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    loadCachedTelemetryData(); // Load cached data on initialization
  }

  @override
  void didUpdateWidget(covariant SensorGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auid != widget.auid) {
      // If the auid changes, fetch new data
      fetchTelemetryData(currentTimeRange);
    }
  }

  // Method to fetch telemetry data from the API and cache it
  Future<void> fetchTelemetryData(String timeRange) async {
    setState(() {
      isLoading = true; // Set loading state
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // Construct API URL using base from widget
      final apiUrl = '${widget.base}filter-data'; // Construct URL

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "auid": widget.auid,
          "userid": userId,
          "timeRange": timeRange,
          "limit": 50
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Cache the telemetry data with time range in key
        await prefs.setString('$cacheKey-${widget.auid}-$timeRange',
            jsonEncode(jsonResponse['telemetryData']));
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
    final cachedData =
        prefs.getString('$cacheKey-${widget.auid}-$currentTimeRange');
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

    return Padding(
      padding: const EdgeInsets.all(0),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show a loading spinner
          : Column(
              children: [
                // Row for Dropdown and Reload Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Align to left
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                Colors.green[100], // Dropdown background color
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
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
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.black),
                      onPressed: () {
                        // Refresh the telemetry data
                        fetchTelemetryData(currentTimeRange);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Container for the chart
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: SfCartesianChart(
                      // Set the chart title
                      title: ChartTitle(
                        text: _buildChartTitle(startDate,
                            endDate), // Use a helper function for title text
                        textStyle: const TextStyle(
                          fontSize: 14, // Smaller font size for readability
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w300,
                          color: Color.fromARGB(
                              255, 0, 0, 0), // Color of the title text
                        ),
                      ),
                      // Enable the legend
                      legend: const Legend(isVisible: false),
                      // Enable pinch zoom
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: true, // Enable pinch to zoom
                        enablePanning: true, // Enable panning
                      ),
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
                      primaryYAxis: const NumericAxis(
                        labelStyle: TextStyle(
                          color: Colors.black54,
                        ),
                        axisLine: AxisLine(width: 0),
                        majorTickLines: MajorTickLines(size: 0),
                        majorGridLines: MajorGridLines(
                          color: Colors.grey,
                          dashArray: [5, 5],
                        ),
                      ),
                      plotAreaBorderWidth: 0,
                      series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
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

  String _buildChartTitle(DateTime? startDate, DateTime? endDate) {
    final start =
        startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : '';
    final end = endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : '';

    return 'Graph of $selectedDataPoint\nTime: $start - $end';
  }
}
