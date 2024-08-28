import 'dart:async';
import 'dart:convert';
import 'package:craftedclimate/forgotPassword/custom_button.dart';
import 'package:craftedclimate/loginscreen/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  String? otpCode; // To store the OTP code entered by the user
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";
  late Timer _timer;
  int _timeLeft = 900;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_timeLeft == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void verifyOtp() async {
 
    if (otpCode != null && otpCode!.length == 6) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl//verify-otp-signup'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'email': widget.email,
            'otp': otpCode!,
          }),
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully')),
          );
          // Navigate to the login screen or directly log the user in
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid OTP. Please try again.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: ${e.toString()}')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP code')),
      );
    }
  }

  void resendOtp() async {
    // Resend OTP code to the user's email
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-password-otp'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP code has been resent')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to resend OTP code')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}')),
        );
      }
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
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            SvgPicture.asset(
              'assets/images/reset3.svg',
              height: MediaQuery.of(context).size.width * 0.8,
            ),
            const SizedBox(
              height: 50,
            ),
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const Text(
              'Enter the six-digit code sent to your email address',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(
              height: 30,
            ),
            Pinput(
              length: 6,
              showCursor: true,
              onCompleted: (pin) => setState(() {
                otpCode = pin;
              }),
            ),
            const SizedBox(
              height: 30,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Code will expire in ${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')} minutes",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
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
                  onTap:_timeLeft == 0 ? resendOtp : null, // Resend OTP on tap
                  child:  Text(
                    "RESEND OTP",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _timeLeft == 0 ? Colors.blueAccent : Colors.grey[400],
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CustomButton(
                onTap: verifyOtp,
                color: Colors.green,
                label: 'Verify Code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
