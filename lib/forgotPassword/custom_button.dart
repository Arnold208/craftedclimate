import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String label; // New parameter to accept the label text

  const CustomButton({
    super.key,
    required this.onTap,
    required this.color,
    required this.label, // Make sure to pass the label text when creating the button
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color,
          ),
          height: 40,
          width: MediaQuery.of(context).size.width * 0.8,
          child: Center(
            child: Text(
              label, // Use the label parameter here
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}