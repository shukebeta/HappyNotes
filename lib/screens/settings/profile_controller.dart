import 'package:flutter/foundation.dart'; // Import ChangeNotifier
import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/entities/user.dart';

class ProfileController extends ChangeNotifier {
  // State variables
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters for UI to access state
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor - Fetch user info immediately
  ProfileController() {
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners(); // Notify UI about loading start

    try {
      // Direct static call since AccountApi methods are static
      final user = await AccountApi.getMyInformation();
      _currentUser = user;
    } catch (e) {
      // Improve error handling - maybe log the error or show a user-friendly message
      debugPrint("Error fetching user info: $e"); // Use debugPrint
      _errorMessage = "Failed to load profile information.";
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI about loading end and state changes
    }
  }

  // Placeholder for changePassword - will need current/new password args
  Future<bool> changePassword(String currentPassword, String newPassword) async {
     _isLoading = true;
     _errorMessage = null;
     notifyListeners();
     bool success = false;
     try {
        await AccountApi.changePassword(currentPassword, newPassword);
        // Optionally re-fetch user info or assume success
        _errorMessage = "Password changed successfully."; // Or handle via return value
        success = true;
     } catch (e) {
        debugPrint("Error changing password: $e");
        // Attempt to parse specific error messages from API if possible
        _errorMessage = "Failed to change password. Please check current password.";
        success = false;
     } finally {
        _isLoading = false;
        notifyListeners();
     }
     return success;
  }
}