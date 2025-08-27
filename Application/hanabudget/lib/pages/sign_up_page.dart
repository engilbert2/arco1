import 'package:flutter/material.dart';
import 'package:hanabudget/services/auth_service.dart';
import 'dart:async'; // Add this import for Timer

// Simple debouncer class
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedSecurityQuestion;

  // Enhanced username validation variables
  bool _checkingUsername = false;
  bool _usernameAvailable = false;
  String _usernameMessage = '';
  bool _hasCheckedUsername = false; // Track if we've checked at least once
  final Debouncer _usernameDebouncer = Debouncer(delay: Duration(milliseconds: 600));

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();

  final List<String> _securityQuestions = [
    'In what town was your first job?',
    'What is your mother\'s maiden name?',
    'What was the name of your first pet?',
    'What elementary school did you attend?',
    'What is the name of your favorite teacher?',
  ];

  @override
  void initState() {
    super.initState();

    // Listen to username changes with enhanced validation
    _usernameController.addListener(() {
      final username = _usernameController.text.trim();

      // Reset state when user types
      setState(() {
        _hasCheckedUsername = false;
      });

      if (username.length >= 3) {
        _usernameDebouncer.call(() {
          _checkUsernameAvailability(username);
        });
      } else if (username.isNotEmpty && username.length < 3) {
        setState(() {
          _usernameMessage = 'Username must be at least 3 characters';
          _usernameAvailable = false;
          _checkingUsername = false;
          _hasCheckedUsername = false;
        });
      } else {
        setState(() {
          _usernameMessage = '';
          _usernameAvailable = false;
          _checkingUsername = false;
          _hasCheckedUsername = false;
        });
      }
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) return;

    setState(() {
      _checkingUsername = true;
      _usernameMessage = 'Checking availability...';
    });

    try {
      final result = await _authService.checkUsernameAvailability(username);

      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _checkingUsername = false;
          _hasCheckedUsername = true;
          _usernameAvailable = result['available'] ?? false;

          if (_usernameAvailable) {
            _usernameMessage = 'Username is available';
          } else {
            _usernameMessage = 'Username already exists';
          }
        });
      }
    } catch (e) {
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _checkingUsername = false;
          _hasCheckedUsername = true;
          _usernameAvailable = false;
          _usernameMessage = 'Error checking username availability';
        });
      }
    }
  }

  // Enhanced validator for username field
  String? _usernameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }

    final username = value.trim();

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    // Only show availability error if we've checked and it's not available
    if (_hasCheckedUsername && !_usernameAvailable) {
      return null; // We'll show the message below the field instead
    }

    return null;
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    // Check username availability one more time before proceeding
    final username = _usernameController.text.trim();
    if (username.isNotEmpty && (!_hasCheckedUsername || !_usernameAvailable)) {
      // Force check username if not checked or not available
      await _checkUsernameAvailability(username);

      if (!_usernameAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username "$username" is already taken. Please choose another username.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUpUser(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        securityQuestion: _selectedSecurityQuestion,
        securityAnswer: _securityAnswerController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth > 500 ? 500 : constraints.maxWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Enhanced Username Field with better validation display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _hasCheckedUsername && !_usernameAvailable
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _hasCheckedUsername && !_usernameAvailable
                                    ? Colors.red
                                    : Colors.teal,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            suffixIcon: _checkingUsername
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                ),
                              ),
                            )
                                : _hasCheckedUsername && _usernameController.text.isNotEmpty
                                ? Icon(
                              _usernameAvailable ? Icons.check_circle : Icons.error,
                              color: _usernameAvailable ? Colors.green : Colors.red,
                            )
                                : null,
                          ),
                          onChanged: (value) {
                            // Trigger form validation
                            if (_formKey.currentState != null) {
                              _formKey.currentState!.validate();
                            }
                          },
                          validator: _usernameValidator,
                        ),

                        // Custom message display below the field
                        if (_usernameMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Row(
                              children: [
                                Icon(
                                  _checkingUsername
                                      ? Icons.hourglass_empty
                                      : _usernameAvailable
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  size: 16,
                                  color: _checkingUsername
                                      ? Colors.grey
                                      : _usernameAvailable
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _usernameMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _checkingUsername
                                        ? Colors.grey
                                        : _usernameAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: _usernameAvailable ? FontWeight.normal : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // First Name Field
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name Field
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() =>
                            _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword =
                            !_obscureConfirmPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Security Question Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedSecurityQuestion,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Security Question',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: _securityQuestions.map((question) {
                        return DropdownMenuItem(
                          value: question,
                          child: Text(
                            question,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSecurityQuestion = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a security question';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Security Answer Field
                    TextFormField(
                      controller: _securityAnswerController,
                      decoration: const InputDecoration(
                        labelText: 'Security Answer',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.quiz),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your security answer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Enhanced Sign Up Button - disabled if username not available
                    ElevatedButton(
                      onPressed: (_isLoading || (_hasCheckedUsername && !_usernameAvailable))
                          ? null
                          : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_hasCheckedUsername && !_usernameAvailable)
                            ? Colors.grey
                            : Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : Text(
                        (_hasCheckedUsername && !_usernameAvailable)
                            ? 'Change Username'
                            : 'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(
                            context, '/login'),
                        child: Text(
                          'Already have an account? Sign In',
                          style: TextStyle(color: Colors.teal[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _usernameDebouncer.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }
}