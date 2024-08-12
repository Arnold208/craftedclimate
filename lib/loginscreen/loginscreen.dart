import 'dart:convert';
import 'package:craftedclimate/homescreen/homescreen.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final String baseUrl = "https://cctelemetry-dev.azurewebsites.net";

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
      Uri.parse('$baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        // 'email': _emailController.text,
        // 'password': _passwordController.text,
           'email': 'cmatthyas09@ymail.com',
          'password':'123456789',
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Login failed: ${response.reasonPhrase}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final  width = MediaQuery.of(context).size.width;
    final  height = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/logo/cc_logo_raw.png', width: width * 0.7 , height: height * 0.4,),
            ),
             SizedBox(height: height * 0.1),
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
             SizedBox(height: height * 0.1),
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
          
             SizedBox(height: height * 0.02),
             Align(
              alignment: Alignment.centerRight,
               child: TextButton(
                onPressed: () {
                  // Insert forgot password logic here
                },
                child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 2, 133, 239)),
                  ),
                ),
                             ),
             ),
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
             SizedBox(height: height * 0.1),
              
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
         
              const SizedBox(height: 25),
            Expanded(
              child: CheckboxListTile(
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
            ),
           
          ],
        ),
      ),
    );
  }
}
