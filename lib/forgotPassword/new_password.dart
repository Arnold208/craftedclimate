import 'dart:convert';

import 'package:craftedclimate/forgotPassword/custom_button.dart';
import 'package:craftedclimate/forgotPassword/custom_text_field.dart';
import 'package:craftedclimate/loginscreen/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewPassword extends StatefulWidget {
  final String otpCode; // Receive OTP code from previous screen
  final String email; // Receive email from previous screen

  const NewPassword({super.key, required this.otpCode, required this.email});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void createPassword() async {
    setState(() {
      _isLoading = true;
    });
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp-reset-password'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
          'otp': widget.otpCode,
          'newPassword': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Password reset successful, navigate to login or success page
        // Navigator.pushNamed(context, '/login'); // Replace with your desired route

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String errorMessage =
            responseData['message'] ?? 'An unknown error occurred';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Text(
                'Enter your new password to complete reset process',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(
                height: 15,
              ),
              CustomTextField(
                controller: _passwordController,
                label: 'New Password',
                obscureText: true,
              ),
              const SizedBox(
                height: 20,
              ),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscureText: true,
              ),
              const SizedBox(
                height: 20,
              ),
              CustomButton(
                onTap: createPassword,
                color: Colors.green,
                label: _isLoading ? 'Resetting Password....' : 'Create Password',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
