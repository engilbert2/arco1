import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static UserSession? _instance;
  static UserSession get instance => _instance ??= UserSession._internal();

  UserSession._internal();

  // User session properties
  bool _isLoggedIn = false;
  String? _userFirstName;
  String? _userId;
  String? _userEmail;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get userFirstName => _userFirstName;
  String? get userId => _userId;
  String? get userEmail => _userEmail;

  // Load session from SharedPreferences (or your MongoDB implementation)
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userFirstName = prefs.getString('userFirstName');
      _userId = prefs.getString('userId');
      _userEmail = prefs.getString('userEmail');

      return _isLoggedIn;
    } catch (e) {
      print('Error loading session: $e');
      return false;
    }
  }

  // Save session to SharedPreferences (or your MongoDB implementation)
  Future<void> saveSession({
    required String userId,
    required String firstName,
    String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = true;
      _userFirstName = firstName;
      _userId = userId;
      _userEmail = email;

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userFirstName', firstName);
      await prefs.setString('userId', userId);
      if (email != null) {
        await prefs.setString('userEmail', email);
      }
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Logout and clear session
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear session data
      _isLoggedIn = false;
      _userFirstName = null;
      _userId = null;
      _userEmail = null;

      // Clear SharedPreferences
      await prefs.remove('isLoggedIn');
      await prefs.remove('userFirstName');
      await prefs.remove('userId');
      await prefs.remove('userEmail');

      // If you're using MongoDB, add your MongoDB logout logic here

    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _isLoggedIn && _userId != null;
  }

  // Update user information
  Future<void> updateUserInfo({
    String? firstName,
    String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (firstName != null) {
        _userFirstName = firstName;
        await prefs.setString('userFirstName', firstName);
      }

      if (email != null) {
        _userEmail = email;
        await prefs.setString('userEmail', email);
      }
    } catch (e) {
      print('Error updating user info: $e');
    }
  }
}