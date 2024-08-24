import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FCMTokenManager {
  static const String _fcmTokenKey = 'fcmToken';
  static const String _userIdKey = 'userId';
  static const String _serverUrl =
      'https://cctelemetry-dev.azurewebsites.net/updateToken'; // Replace with your server URL

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> checkAndUpdateFCMToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the current FCM token
    String? currentToken = await _firebaseMessaging.getToken();
    String? storedToken = prefs.getString(_fcmTokenKey);
    String? userId = prefs.getString(_userIdKey);

    // If the token has changed or it's the first time getting the token
    if (currentToken != null && currentToken != storedToken) {
      // Store the new token in SharedPreferences
      await prefs.setString(_fcmTokenKey, currentToken);

      // Send the new token to the server
      if (userId != null) {
        await _sendTokenToServer(userId, currentToken);
      }
    }
  }

  Future<void> _sendTokenToServer(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: '''{
          "userId": "$userId",
          "fcmToken": "$token"
        }''',
      );

      if (response.statusCode == 200) {
        print('Token updated successfully on the server.');
      } else {
        print(
            'Failed to update token on the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }
}
