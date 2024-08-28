import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
    final bool obscureText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label, 
    this.obscureText = false,

  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color.fromARGB(146, 240, 240, 240),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }
}