import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Function to make API call for login
  static Future<String?> login(String username, String password) async {
    final url = Uri.parse('http://localhost:5012/account/login');
    final response = await http.post(
      url,
      body: jsonEncode({'username': username, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    final jsonResponse = json.decode(response.body);

    if (jsonResponse['successful']) {
      // Extract and return the access token
      return jsonResponse['data']['token'];
    } else {
      // Return null if login is unsuccessful
      return null;
    }
  }

  // Function to save the access token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }
}
