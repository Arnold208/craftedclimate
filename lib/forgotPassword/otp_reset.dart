import 'dart:convert';
import 'package:craftedclimate/forgotPassword/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;

class OtpReset extends StatefulWidget {
  final String email;
  final void Function(String otpCode) onOtpVerified; // Callback function

  const OtpReset({
    super.key,
    required this.email,
    required this.onOtpVerified,
  });

  @override
  State<OtpReset> createState() => _OtpResetState();
}

class _OtpResetState extends State<OtpReset> {
  String? otpCode; // To store the OTP code entered by the user
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";

  void verifyOtp() {
    if (otpCode != null && otpCode!.length == 6) {
      widget.onOtpVerified(otpCode!); // Use the callback function
    } else {
      // Show error if OTP code is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP code')),
      );
    }
  }

  void resendOtp() async {
    // Resend OTP code to the user's email
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-otp'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP code has been resent')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend OTP code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const Text(
              'Enter the six-digit code sent to your email address',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(
              height: 20,
            ),
            Pinput(
              length: 6,
              showCursor: true,
              onCompleted: (pin) => setState(() {
                otpCode = pin;
              }),
            ),
            const SizedBox(
              height: 15,
            ),
            const Align(
              alignment: Alignment.center,
              child: Text(
                "Code will expire in 15:00 ",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive any code? ",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                ),
                const SizedBox(
                  width: 3,
                ),
                GestureDetector(
                  onTap: resendOtp, // Resend OTP on tap
                  child: const Text(
                    "RESEND OTP",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blueAccent,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            CustomButton(
              onTap: verifyOtp,
              color: Colors.green,
              label: 'Verify Code',
            ),
          ],
        ),
      ),
    );
  }
}
