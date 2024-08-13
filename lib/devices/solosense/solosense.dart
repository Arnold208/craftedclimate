import 'dart:convert';
import 'package:craftedclimate/aqi/custom_gauge.dart';
import 'package:craftedclimate/graph/custom_graph.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class solosenseScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const solosenseScreen({required this.device, super.key});

  @override
  State<solosenseScreen> createState() => _solosenseScreenState();
}

class _solosenseScreenState extends State<solosenseScreen> {
  Map<String, dynamic>? dataPoints;
  String? timestamp;
  bool isLoading = true;
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";

  final Map<String, dynamic> _datapoints = {
    "Temperature": Icons.thermostat,
    "Pressure": Icons.speed,
    "Humidity": Icons.water_damage,
    "Gas Resistance": Icons.local_gas_station,
    "Altitude": Icons.assessment,
    "CO Level": Icons.cloud,
    "Alcohol Level": Icons.local_drink,
    "CO2 Level": Icons.cloud_circle,
    "Toluene Level": Icons.bubble_chart,
    "NH4 Level": Icons.bubble_chart,
    "Acetone Level": Icons.bubble_chart,
    "Solar Panel Data": Icons.wb_sunny,
    "Battery Data": Icons.battery_full,
  };

  final Map<String, String> _datapointMappings = {
    "Temperature": "a",
    "Pressure": "b",
    "Humidity": "c",
    "Gas Resistance": "d",
    "Altitude": "e",
    "CO Level": "f",
    "Alcohol Level": "g",
    "CO2 Level": "h",
    "Toluene Level": "i",
    "NH4 Level": "j",
    "Acetone Level": "k",
    "Solar Panel Data": "l",
    "Battery Data": "m",
    "Constant n": "n",
    "Constant o": "o",
  };

  final Set<String> _selectedDatapoints = {};
  final Set<String> _selectedDatapointsForSelectDialog = {};
  final TextEditingController _frequencyController = TextEditingController();
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _editableDataPoints = {};

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _loadSelectedDatapoints();
    _loadEditableDataPoints();
    fetchDataPoints();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSettings = prefs.getString('sensorSettings');
    if (savedSettings != null) {
      final Map<String, dynamic> settings = json.decode(savedSettings);
      setState(() {
        _frequencyController.text = settings['frequency'].toString();
        _selectedDatapoints.addAll(settings['datapoint'].map<String>((dp) =>
            _datapointMappings.entries
                .firstWhere((entry) => entry.value == dp)
                .key));
        _selectedDatapoints.addAll(
            ['Constant n', 'Constant o']); // Ensure 'n' and 'o' are included
      });
    }
  }

  Future<void> _loadSelectedDatapoints() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDatapoints = prefs.getString('selectedDatapoints');
    if (savedDatapoints != null) {
      final List<String> datapoints =
          List<String>.from(json.decode(savedDatapoints));
      setState(() {
        _selectedDatapointsForSelectDialog.addAll(datapoints);
      });
    }
  }

  Future<void> _storeSelectedDatapoints() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> datapointsList = _selectedDatapointsForSelectDialog.toList();
    String jsonDatapoints = json.encode(datapointsList);
    await prefs.setString('selectedDatapoints', jsonDatapoints);
    print('Saved selected datapoints: $jsonDatapoints');
  }

  Future<void> _loadEditableDataPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDataPoints = prefs.getString('editableDataPoints');
    if (savedDataPoints != null) {
      final Map<String, Map<String, dynamic>> dataPoints =
          Map<String, Map<String, dynamic>>.from(json.decode(savedDataPoints));
      setState(() {
        _editableDataPoints.addAll(dataPoints);
      });
    }
  }

  Future<void> _storeEditableDataPoints() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonDataPoints = json.encode(_editableDataPoints);
    await prefs.setString('editableDataPoints', jsonDataPoints);
    print('Saved editable datapoints: $jsonDataPoints');
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
                      ..._datapoints.keys.map((String key) {
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(_datapoints[key], color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(child: Text(key)),
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
                      // Ensure 'n' and 'o' are always included
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
                                    _datapoints.containsKey(key)
                                        ? _datapoints[key]
                                        : Icons.device_unknown,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(key)),
                                ],
                              ),
                              value: _selectedDatapointsForSelectDialog
                                  .contains(key),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedDatapointsForSelectDialog.add(key);
                                  } else {
                                    _selectedDatapointsForSelectDialog
                                        .remove(key);
                                  }
                                });
                                _storeSelectedDatapoints();
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

  void _showEditDatapointDialog(String key) {
    IconData selectedIcon =
        _editableDataPoints[key]?['icon'] ?? _getMetricIcon(key);
    TextEditingController unitController = TextEditingController(
      text: _editableDataPoints[key]?['unit'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Datapoint'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<IconData>(
                      decoration: const InputDecoration(labelText: 'Select Icon'),
                      value: selectedIcon,
                      items: _datapoints.values.map((iconData) {
                        return DropdownMenuItem<IconData>(
                          value: iconData,
                          child: Icon(iconData),
                        );
                      }).toList(),
                      onChanged: (IconData? newIcon) {
                        setState(() {
                          selectedIcon = newIcon!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    setState(() {
                      _editableDataPoints[key] = {
                        'icon': selectedIcon,
                        'unit': unitController.text,
                      };
                    });
                    _storeEditableDataPoints();
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
          final data = jsonResponse['data'][0]['data'];

          setState(() {
            timestamp = DateTime.parse(data['timestamp']).toLocal().toString();
            dataPoints = data != null ? Map<String, dynamic>.from(data) : {};
            _isLoading = false;
          });
        } else {
          print('Error fetching data points: ${response.statusCode}');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching data points: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('User ID not found');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    final jsonBody = _formatToJson();
    final response = await http.post(
      Uri.parse('$baseUrl/solo-config'),
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

      print(jsonBody);
    } else {
      _showResponseDialog('Error', 'Failed to save settings.');
    }
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

  String _formatToJson() {
    List<String> selectedKeys = _selectedDatapoints.map((key) {
      return _datapointMappings[key]!;
    }).toList();

    Map<String, dynamic> jsonBody = {
      "datapoint": selectedKeys,
      "auid": widget.device['deviceId'],
      "frequency": int.parse(_frequencyController.text),
    };

    return json.encode(jsonBody);
  }

  Future<void> _storeSettings(String jsonBody) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('sensorSettings', jsonBody);
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
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),

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
                      if (dataPoints != null && dataPoints!['co2Level'] != null)
                        Center(
                          child: CustomGauge(
                            value: (dataPoints!['co2Level'] as num).toDouble(),
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

                      const SizedBox(height: 16),

                      if (dataPoints != null)
                        _buildMetricGrid()
                      else
                        const Center(
                          child: Text(
                            'No telemetry from sensor',
                            style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w400,
                                color: Color.fromARGB(255, 255, 0, 0)),
                          ),
                        ),

                      const SizedBox(height: 16),
                      // History title
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
                        // width: 600, // Adjust the height as needed
                        child: SensorGraphWidget(
                          auid: widget.device['deviceId'],
                          base:
                              "https://cctelemetry-dev.azurewebsites.net/solo-",
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

  Widget _buildMetricGrid() {
    if (dataPoints == null || _selectedDatapointsForSelectDialog.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _selectedDatapointsForSelectDialog.length,
      itemBuilder: (context, index) {
        final key = _selectedDatapointsForSelectDialog.elementAt(index);
        if (!dataPoints!.containsKey(key)) {
          return const SizedBox.shrink();
        }

        final value = dataPoints![key].toString();
        return GestureDetector(
          onLongPress: () {
            _showEditDatapointDialog(key);
          },
          child: _buildMetricCard(
            _editableDataPoints[key]?['name'] ?? key,
            value,
            _editableDataPoints[key]?['icon'] ?? _getMetricIcon(key),
            _editableDataPoints[key]?['unit'] ?? '',
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, String unit) {
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
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 0, 0, 0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$value $unit',
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

  IconData _getMetricIcon(String key) {
    switch (key) {
      case 'temperature':
        return Icons.thermostat;
      case 'pressure':
        return Icons.speed;
      case 'humidity':
        return Icons.water_damage;
      case 'gasResistance':
        return Icons.local_gas_station;
      case 'altitude':
        return Icons.assessment;
      case 'coLevel':
        return Icons.cloud;
      case 'alcoholLevel':
        return Icons.local_drink;
      case 'co2Level':
        return Icons.cloud_circle;
      case 'toluenLevel':
      case 'nh4Level':
      case 'acetoneLevel':
        return Icons.bubble_chart;
      case 'solarPanelData':
        return Icons.wb_sunny;
      case 'batteryData':
        return Icons.battery_full;
      default:
        return Icons.device_unknown;
    }
  }
}
