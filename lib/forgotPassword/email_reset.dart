import 'dart:async';
import 'dart:convert';

import 'package:craftedclimate/forgotPassword/custom_button.dart';
import 'package:craftedclimate/forgotPassword/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailReset extends StatefulWidget {
  final Function(String) onEmailVerified; // Callback to switch pages with email

  const EmailReset({super.key, required this.onEmailVerified});

  @override
  State<EmailReset> createState() => _EmailResetState();
}

class _EmailResetState extends State<EmailReset> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
      final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void submitEmail() async {
    setState(() {
      _isLoading = true;
    });

    if (!isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': _emailController.text,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'The connection has timed out, please try again.');
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 && mounted) {
        widget.onEmailVerified(_emailController.text); // Use callback to pass email
      } else {
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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forgot Password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const Text(
            'Enter your email to receive a verification code to reset your password',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(
            height: 15,
          ),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
          ),
          const SizedBox(
            height: 40,
          ),
          CustomButton(
            onTap: submitEmail,
            color: Colors.green,
            label: _isLoading ? 'Verifying ...' : 'Verify Email',
          ),
        ],
      ),
    );
  }
}
