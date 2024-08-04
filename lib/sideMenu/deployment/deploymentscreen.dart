import 'package:flutter/material.dart';

class Deploymentscreen extends StatefulWidget {
  const Deploymentscreen({super.key});

  @override
  State<Deploymentscreen> createState() => _DeploymentscreenState();
}

class _DeploymentscreenState extends State<Deploymentscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Deployments",
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
              Icons.device_hub,
              size: 80, // Make the icon large to stand out
              color: Color.fromARGB(255, 3, 55, 132),
            ),
            SizedBox(height: 20), // Add spacing between the icon and text
            Text(
              "Create and Edit Deployments",
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
