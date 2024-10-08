import 'dart:convert';
import 'package:craftedclimate/aqi/custom_gauge.dart';
import 'package:craftedclimate/graph/custom_graph.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SensorLoraScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const SensorLoraScreen({required this.device, super.key});

  @override
  State<SensorLoraScreen> createState() => _SensorLoraScreenState();
}

class _SensorLoraScreenState extends State<SensorLoraScreen> {
  Map<String, dynamic>? dataPoints;
  String? timestamp;
  bool isLoading = true;
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";

  final Set<String> _selectedDatapoints = {};
  final TextEditingController _frequencyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    fetchDataPoints();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSettings = prefs.getString('sensorSettings');
    if (savedSettings != null) {
      final Map<String, dynamic> settings = json.decode(savedSettings);
      setState(() {
        _frequencyController.text = settings['frequency'].toString();
        _selectedDatapoints
            .addAll(settings['datapoint'].map<String>((dp) => dp.toString()));
      });
    }
  }

  Future<void> fetchDataPoints() async {
    setState(() {
      _isLoading = true;
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
          if (jsonResponse['data'].isNotEmpty) {
            final data = jsonResponse['data'][0]['data'];

            setState(() {
              timestamp =
                  DateTime.parse(data['timestamp']).toLocal().toString();
              dataPoints = data != null ? Map<String, dynamic>.from(data) : {};
              _isLoading = false;
            });

            Logger().d('Data Points Loaded: $dataPoints'); // Debug statement
          }
        } else {
          Logger().d('Error fetching data points: ${response.statusCode}');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        Logger().d('Error fetching data points: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      Logger().d('User ID not found');
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIconForKey(String key) {
    if (key.toLowerCase().contains('temperature')) {
      return Icons.thermostat;
    } else if (key.toLowerCase().contains('pressure')) {
      return Icons.speed;
    } else if (key.toLowerCase().contains('humidity')) {
      return Icons.water_damage;
    } else if (key.toLowerCase().contains('gas')) {
      return Icons.local_gas_station;
    } else if (key.toLowerCase().contains('altitude')) {
      return Icons.assessment;
    } else if (key.toLowerCase().contains('battery')) {
      return Icons.battery_full;
    } else if (key.toLowerCase().contains('light')) {
      return Icons.wb_sunny;
    } else {
      return Icons.device_unknown; // Default icon for unknown data points
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> location = jsonDecode(widget.device['location']);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.device['name'],
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 65, 161, 70),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchDataPoints,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  statusColor:
                                      widget.device['status'] == 'online'
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
                          if (dataPoints != null &&
                              dataPoints!['co2Level'] != null)
                            Center(
                              child: CustomGauge(
                                value:
                                    (dataPoints!['co2Level'] as num).toDouble(),
                                minValue: 0,
                                maxValue: 2100,
                                width: 200,
                                height: 200,
                              ),
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
                                fontSize: 20,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    // Placing the GridView inside the Column with proper constraints
                    if (dataPoints != null)
                      _buildMetricGrid()
                    else
                      _noTelemetryMessage(),

                    // History title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HISTORY',
                            style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 400,
                            child: SensorGraphWidget(
                              auid: widget.device['deviceId'],
                              base:
                                  "https://cctelemetry-dev.azurewebsites.net/lora-",
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricGrid() {
    if (dataPoints == null || dataPoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 1.0,
        ),
        itemCount: dataPoints!.length,
        itemBuilder: (context, index) {
          final key = dataPoints!.keys.elementAt(index);

          // Exclude unwanted keys
          if (key == 'auid' ||
              key == 'timestamp' ||
              key == 'model' ||
              key == 'devid') {
            return const SizedBox.shrink();
          }

          final value = dataPoints![key].toString();
          return _buildMetricCard(
            key,
            value,
            _getIconForKey(key),
          );
        },
      ),
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
        padding: const EdgeInsets.all(12), // Adjust padding to reduce top space
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 32),
            const SizedBox(height: 4), // Reduce gap
            Text(
              _formatMetricName(title),
              style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 0, 0, 0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4), // Reduce gap
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Color.fromARGB(255, 0, 0, 0)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMetricName(String key) {
    // Capitalize the first letter and replace underscores with spaces
    return key.replaceAllMapped(RegExp(r'(^\w)|(_\w)'),
        (match) => match.group(0)!.toUpperCase().replaceAll('_', ' '));
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
                  _showFullTextDialog(context, value);
                },
                child: Text(
                  truncateWithEllipsis(10, value), // Truncated text
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: statusColor ?? const Color.fromARGB(255, 0, 0, 0),
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

  String truncateWithEllipsis(int cutoff, String text) {
    return (text.length <= cutoff) ? text : '${text.substring(0, cutoff)}...';
  }

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
              maxHeight: MediaQuery.of(context).size.height * 0.3,
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

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsItem(
                icon: Icons.settings,
                text: 'Configure Sensor',
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showConfigureSensorDialog();
                },
              ),
              _buildSettingsItem(
                icon: Icons.bar_chart,
                text: 'Select Datapoint',
                iconColor: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _showSelectDatapointDialog();
                },
              ),
              _buildSettingsItem(
                icon: Icons.restart_alt,
                text: 'Restart Sensor',
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  // Handle restart sensor action
                },
              ),
              _buildSettingsItem(
                icon: Icons.system_update,
                text: 'Update Firmware',
                iconColor: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  // Handle update firmware action
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 0, 0, 0)),
      ),
      onTap: onTap,
    );
  }

  void _showConfigureSensorDialog() {
    Set<String> selectedDatapointsForConfigureDialog = {
      ..._selectedDatapoints
    };
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Configure Sensor',
                      style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.green),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              'Configure Sensor Information',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w400,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                            content: const Text(
                              'Here you can configure the sensor by selecting up to 6 datapoints and setting the frequency.',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w300,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Raleway',
                                      fontWeight: FontWeight.w300,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...dataPoints!.keys.map((String key) {
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(_getIconForKey(key), color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_formatMetricName(key))),
                            ],
                          ),
                          value: selectedDatapointsForConfigureDialog
                              .contains(key),
                          onChanged: (bool? value) {
                            if (value == true &&
                                selectedDatapointsForConfigureDialog.length >=
                                    7) {
                              return; // Prevent checking more than 6 boxes
                            }
                            setState(() {
                              if (value == true) {
                                selectedDatapointsForConfigureDialog.add(key);
                              } else {
                                selectedDatapointsForConfigureDialog
                                    .remove(key);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _frequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Frequency (min 15)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a frequency';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 15) {
                            return 'Frequency must be at least 15';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Close',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w300,
                        color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    'Save',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w300,
                        color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDatapoints
                        ..clear()
                        ..addAll(selectedDatapointsForConfigureDialog);
                      _selectedDatapoints.addAll(['Constant n', 'Constant o']);
                    });
                    _storeSettings(_formatToJson());
                    Navigator.of(context).pop();
                    _showSaveConfirmationDialog();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelectDatapointDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Datapoint',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.green),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              'Select Datapoint Information',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w400,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                            content: const Text(
                              'Here you can select which datapoints you want to monitor. '
                              'and analyse.',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w300,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Raleway',
                                      fontWeight: FontWeight.w300,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: dataPoints != null
                        ? dataPoints!.entries.where((entry) {
                            final key = entry.key;
                            return key != 'auid' &&
                                key != 'timestamp' &&
                                key != 'deviceId' &&
                                key != '_id' &&
                                key != '__v' &&
                                key != 'status';
                          }).map((entry) {
                            final key = entry.key;
                            return CheckboxListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    _getIconForKey(key),
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_formatMetricName(key))),
                                ],
                              ),
                              value: _selectedDatapoints.contains(key),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedDatapoints.add(key);
                                  } else {
                                    _selectedDatapoints.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList()
                        : [],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatToJson() {
    Map<String, dynamic> jsonBody = {
      "datapoint": _selectedDatapoints.toList(),
      "auid": widget.device['deviceId'],
      "frequency": int.parse(_frequencyController.text),
    };

    return json.encode(jsonBody);
  }

  Future<void> _storeSettings(String jsonBody) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('sensorSettings', jsonBody);
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Save'),
          content:
              const Text('Are you sure you want to save settings on sensor?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    final jsonBody = _formatToJson();
    final response = await http.post(
      Uri.parse('$baseUrl/lora-config'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonBody,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      _showResponseDialog('Success', 'Settings saved successfully.');
      _storeSettings(jsonBody);
    } else {
      _showResponseDialog('Error', 'Failed to save settings.');
    }
  }

  void _showResponseDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _noTelemetryMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Text(
          'No telemetry from sensor',
          style: TextStyle(
              fontSize: 20,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 255, 0, 0)),
        ),
      ),
    );
  }
}
