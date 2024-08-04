import 'package:flutter/material.dart';

class Mapscreen extends StatefulWidget {
  const Mapscreen({super.key});

  @override
  State<Mapscreen> createState() => _MapscreenState();
}

class _MapscreenState extends State<Mapscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Map Overview",
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 65, 161, 70),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options action
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 80, // Large icon size for emphasis
              color: Color.fromARGB(255, 3, 55, 132),
            ),
            SizedBox(height: 20), // Spacing between icon and text
            Text(
              "Locate your devices on Map",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
