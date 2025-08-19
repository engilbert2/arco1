import 'package:hanabudget/database/mongo_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final MongoDBService _mongoService = MongoDBService();

  // ==============================
  // SIGN UP USER
  // ==============================
  Future<Map<String, dynamic>> signUpUser({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    String? email,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      // prepare user data
      Map<String, dynamic> userData = {
        'username': username.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'password': password,
        'email': email?.trim() ?? '',
        'securityQuestion': securityQuestion?.trim() ?? '',
        'securityAnswer': securityAnswer?.trim() ?? '',
      };

      bool success = await _mongoService.createUser(userData);

      if (success) {
        return {
          'success': true,
          'message': 'Account created successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Username already exists or failed to create account.',
        };
      }
    } catch (e) {
      print('Sign up error: $e');
      return {
        'success': false,
        'message': 'Error creating account: ${e.toString()}',
      };
    }
  }

  // ==============================
  // SIGN IN USER
  // ==============================
  Future<Map<String, dynamic>> signInUser({
    required String username,
    required String password,
  }) async {
    try {
      var user = await _mongoService.authenticateUser(username.trim(), password);

      if (user != null) {
        // save user session
        await _saveUserSession(user);

        return {
          'success': true,
          'message': 'Login successful!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid username or password.',
        };
      }
    } catch (e) {
      print('Sign in error: $e');
      return {
        'success': false,
        'message': 'Error signing in: ${e.toString()}',
      };
    }
  }

  // ==============================
  // SAVE USER SESSION LOCALLY
  // ==============================
  Future<void> _saveUserSession(Map<String, dynamic> user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // handle _id (MongoDB ObjectId) and normal id
      String userId = '';
      if (user.containsKey('id')) {
        userId = user['id'].toString();
      } else if (user.containsKey('_id')) {
        userId = user['_id'].toString();
      }

      await prefs.setString('userId', userId);
      await prefs.setString('username', user['username']?.toString() ?? '');
      await prefs.setString('firstName', user['firstName']?.toString() ?? '');
      await prefs.setString('lastName', user['lastName']?.toString() ?? '');
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      print('Error saving user session: $e');
    }
  }

  // ==============================
  // GET CURRENT USER SESSION
  // ==============================
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        return {
          'id': prefs.getString('userId') ?? '',
          'username': prefs.getString('username') ?? '',
          'firstName': prefs.getString('firstName') ?? '',
          'lastName': prefs.getString('lastName') ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // ==============================
  // SIGN OUT USER
  // ==============================
  Future<void> signOut() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // ==============================
  // CHECK IF USER IS LOGGED IN
  // ==============================
  Future<bool> isUserLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
}
