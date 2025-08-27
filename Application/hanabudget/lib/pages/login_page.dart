import 'package:flutter/material.dart';
import 'package:hanabudget/components/my_text_field.dart';
import 'package:hanabudget/components/my_button.dart';
import 'package:hanabudget/components/my_button_sign_up.dart';
import 'package:hanabudget/database/mongo_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanabudget/screens/verification_screen.dart';
import 'package:hanabudget/screens/captcha_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🚀 LoginPage initialized');
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Sign user in method
  Future<void> signUserIn(BuildContext context) async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('🔍 Attempting login for user: $username');

    try {
      // Ensure MongoDB connection
      await MongoDBService().connect();

      // Authenticate with MongoDB
      final user = await MongoDBService().authenticateUser(username, password);

      if (user != null) {
        print('✅ User authenticated successfully: ${user['username']}');
        print('📧 User email: ${user['email']}');

        // Check if email is available for 2FA
        if (user['email'] == null || user['email'].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email found for this account. Please contact support.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Navigate to 2FA verification screen for ALL users
        print('➡️ Navigating to 2FA Verification (Required for all users)');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(userData: user),
          ),
        );
      } else {
        print('❌ Authentication failed - incorrect credentials');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect username or password')),
        );
      }
    } catch (e) {
      print('❌ Error during authentication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ LoginPage building UI');
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/images/logo.png', width: 200, height: 200),
                const SizedBox(height: 30),

                // Username input
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                // Password input
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                // Forgot Password link
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/forgot'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Login button
                _isLoading
                    ? const CircularProgressIndicator()
                    : MyButton(
                  onTap: () => signUserIn(context),
                  text: 'Sign In',
                ),

                const SizedBox(height: 10),
                const Text("Don't have an account?"),
                const SizedBox(height: 10),

                // Sign Up button
                MyButtonSignUp(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}