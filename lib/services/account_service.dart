import 'package:HappyNotes/apis/account_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountService {

  // Function to make API call for login
  static Future<dynamic> login(String username, String password) async {
    var params = {'username': username, 'password': password};
    return (await AccountApi.login(params)).data;
  }

  static Future<dynamic> register(String username, String email, String password) async {
    var params = {'username': username, 'email': email, 'password': password};
    return (await AccountApi.register(params)).data;
  }

  // Function to save the access token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }
}
