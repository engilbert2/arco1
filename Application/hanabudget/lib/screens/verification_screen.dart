import 'package:flutter/material.dart';
import 'package:hanabudget/components/my_button.dart';
import 'package:hanabudget/database/mongo_database.dart';
import 'package:hanabudget/services/email_service.dart';
import 'package:hanabudget/screens/captcha_screen.dart';
import 'package:hanabudget/services/auth_service.dart';
import 'package:hanabudget/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const VerificationScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    print('🎯 Verification screen initialized with userData: ${widget.userData}');
    _sendVerificationEmail();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _controllers[i].text.isEmpty && i > 0) {
          FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
        }
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _isResending = true);

    try {
      // Get user ID - handle both '_id' and 'id' fields
      String userId = widget.userData['_id']?.toString() ?? widget.userData['id']?.toString() ?? '';
      String userEmail = widget.userData['email']?.toString() ?? '';

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      if (userEmail.isEmpty) {
        throw Exception('User email not found');
      }

      print('📧 Generating verification token for userId: $userId, email: $userEmail');

      // Ensure MongoDB connection
      await MongoDBService().connect();

      final token = await MongoDBService().generateVerificationToken(userId, userEmail);
      print('✅ Token generated: $token');

      final emailSent = await EmailService().sendVerificationEmail(userEmail, token);

      if (!emailSent) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send verification email. Please try again.'),
              backgroundColor: Colors.red,
            )
        );
        setState(() => _emailSent = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification code sent to $userEmail'),
              backgroundColor: Colors.green,
            )
        );
        setState(() => _emailSent = true);
      }
    } catch (e) {
      print('❌ Error sending verification email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
      );
      setState(() => _emailSent = false);
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    // Auto-verify if all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _controllers.map((controller) => controller.text).join();

    if (code.length != 6) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a 6-digit code';
      });
      return;
    }

    try {
      // Get user ID - handle both '_id' and 'id' fields
      String userId = widget.userData['_id']?.toString() ?? widget.userData['id']?.toString() ?? '';

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      print('🔍 Verifying code: $code for userId: $userId');

      // Ensure MongoDB connection
      await MongoDBService().connect();

      final isValid = await MongoDBService().verifyToken(userId, code);

      if (isValid) {
        print('✅ 2FA verification successful');

        // Save user session after successful 2FA verification
        final AuthService authService = AuthService();
        await authService.saveUserSession(widget.userData);
        print('✅ User session saved');

        // Check if user needs CAPTCHA or can go directly to homepage
        final prefs = await SharedPreferences.getInstance();
        bool captchaCompleted = prefs.getBool('captcha_completed_${widget.userData['username']}') ?? false;

        if (!captchaCompleted) {
          print('➡️ Navigating to CAPTCHA screen');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CaptchaScreen(userData: widget.userData),
              ),
            );
          }
        } else {
          print('➡️ CAPTCHA already completed, navigating to Homepage');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or expired verification code';
        });

        // Clear all fields for retry
        for (var controller in _controllers) {
          controller.clear();
        }
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    } catch (e) {
      print('❌ Verification error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0, // Handle keyboard
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight - 40, // Account for AppBar and padding
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Section
                Column(
                  children: [
                    const Icon(Icons.security, size: 80, color: Colors.blue),
                    const SizedBox(height: 20),
                    const Text(
                      '2FA Required',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'For your security, two-factor authentication is required for all users',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Code sent to: ${widget.userData['email'] ?? 'your email'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Email status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _emailSent ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _emailSent ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _emailSent ? 'Email sent successfully' : 'Email not sent - try resending',
                    style: TextStyle(
                      color: _emailSent ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Code input section
                Column(
                  children: [
                    // Code input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) => _onChanged(value, index),
                          ),
                        );
                      }),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),

                // Action buttons section
                Column(
                  children: [
                    _isLoading
                        ? const CircularProgressIndicator()
                        : MyButton(
                      onTap: _verifyCode,
                      text: 'Verify Code',
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _isResending ? null : _sendVerificationEmail,
                      child: _isResending
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Sending...'),
                        ],
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 5),
                          Text('Resend Code'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}