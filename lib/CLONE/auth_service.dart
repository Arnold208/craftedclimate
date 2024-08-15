// services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> checkIfLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');
    return token != null && await _isTokenValid(token);
  }

  static Future<bool> _isTokenValid(String token) async {
    // Implement your token validation logic here
    return true;
  }
}
