import 'dart:convert';
import 'package:craftedclimate/homescreen/homescreen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _agreeToPrivacyPolicy = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible =
      false; // State variable to track password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('https://cctelemetry-dev.azurewebsites.net/login'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('accessToken', responseData['accessToken']);
      await prefs.setString('refreshToken', responseData['refreshToken']);
      await prefs.setString('userId', responseData['userid']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Login failed: ${response.reasonPhrase}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 45),
            Image.asset('assets/logo/cc_logo_raw.png', height: 200, width: 200),
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 240, 240, 240),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _passwordController,

                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                            !_isPasswordVisible; // Toggle visibility
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 240, 240, 240),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText:
                    !_isPasswordVisible, // Toggle this based on the state
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(height: 25),
            CheckboxListTile(
              title: const Text(
                "I have read and agree to Privacy Policy",
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w300,
                    color: Colors.black),
              ),
              value: _agreeToPrivacyPolicy,
              onChanged: (bool? value) {
                setState(() {
                  _agreeToPrivacyPolicy = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: _agreeToPrivacyPolicy && !_isLoading
                    ? _onLoginPressed
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: _agreeToPrivacyPolicy
                      ? const Color.fromARGB(255, 109, 203, 112)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w400,
                            color: Colors.white),
                      ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: () {
                  // Insert registration logic here
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Insert forgot password logic here
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w300,
                    color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
