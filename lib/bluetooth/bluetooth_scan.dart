import 'package:all_bluetooth/all_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final allBluetooth = AllBluetooth();

class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen> {
  bool listeningForClient = false;
  final bondedDevices = ValueNotifier<List<BluetoothDevice>>([]);
  final scannedDevices = ValueNotifier<List<BluetoothDevice>>([]);

  @override
  void initState() {
    super.initState();
    const MethodChannel("method_channel").invokeMethod("permit");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: allBluetooth.streamBluetoothState,
      builder: (context, snapshot) {
        final bluetoothOn = snapshot.data ?? false;
        return Scaffold(
          floatingActionButton: _buildFloatingActionButton(bluetoothOn),
          appBar: AppBar(
            title: const Text("Bluetooth Connect"),
          ),
          body: _buildBody(bluetoothOn),
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(bool bluetoothOn) {
    if (listeningForClient) {
      return null;
    }
    return FloatingActionButton(
      backgroundColor:
          bluetoothOn ? Theme.of(context).primaryColor : Colors.grey,
      onPressed: bluetoothOn
          ? () {
              allBluetooth.startBluetoothServer();
              setState(() {
                listeningForClient = true;
              });
            }
          : null,
      child: const Icon(Icons.wifi_tethering),
    );
  }

  Widget _buildBody(bool bluetoothOn) {
    if (listeningForClient) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Waiting"),
            const CircularProgressIndicator(),
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  listeningForClient = false;
                });
                allBluetooth.closeConnection();
              },
              child: const Icon(Icons.stop),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildBluetoothControls(bluetoothOn),
        if (!bluetoothOn)
          const Center(child: Text("Turn Bluetooth on"))
        else
          Expanded(
            child: Column(
              children: [
                DeviceListWidget(
                  notifier: bondedDevices,
                  title: "Paired Devices",
                ),
                DeviceListWidget(
                  notifier: scannedDevices,
                  title: "Scanned Devices",
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBluetoothControls(bool bluetoothOn) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            bluetoothOn ? "ON" : "OFF",
            style: TextStyle(
              color: bluetoothOn ? Colors.green : Colors.red,
            ),
          ),
          ElevatedButton(
            onPressed: bluetoothOn
                ? () {
                    allBluetooth.getBondedDevices().then((newDevices) {
                      bondedDevices.value = newDevices;
                    });
                  }
                : null,
            child: const Text("Bonded Devices"),
          ),
          ElevatedButton(
            onPressed: bluetoothOn
                ? () {
                    allBluetooth.startDiscovery();
                  }
                : null,
            child: const Text("Discover"),
          ),
          ElevatedButton(
            onPressed: bluetoothOn
                ? () {
                    allBluetooth.stopDiscovery();
                    allBluetooth.discoverDevices.listen((event) {
                      scannedDevices.value = [...scannedDevices.value, event];
                    });
                  }
                : null,
            child: const Text("Stop Discovery"),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final BluetoothDevice device;

  const ChatScreen({super.key, required this.device});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageListener = ValueNotifier(<String>[]);
  final messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    allBluetooth.listenForData.listen((event) {
      if (event != null) {
        messageListener.value = [
          ...messageListener.value,
          event,
        ];
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          ElevatedButton(
            onPressed: allBluetooth.closeConnection,
            child: const Text("CLOSE"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                  valueListenable: messageListener,
                  builder: (context, messages, child) {
                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                msg,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FloatingActionButton(
                    onPressed: () {
                      final message = messageController.text;
                      allBluetooth.sendMessage(message);
                      messageController.clear();
                      FocusScope.of(context).unfocus();
                    },
                    child: const Icon(Icons.send),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class DeviceListWidget extends StatelessWidget {
  final String title;
  final ValueNotifier<List<BluetoothDevice>> notifier;

  const DeviceListWidget({
    required this.notifier,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, value, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(value.length.toString()),
                ],
              ),
              Flexible(
                fit: FlexFit.loose,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: value.length,
                  itemBuilder: (ctx, index) {
                    final device = value[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      onTap: () async {
                        allBluetooth.connectToDevice(device.address);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
