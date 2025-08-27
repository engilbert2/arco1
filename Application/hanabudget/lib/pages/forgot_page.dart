import 'package:flutter/material.dart';
import 'package:hanabudget/components/my_text_field.dart';
import 'package:hanabudget/components/my_button_forgot.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({Key? key}) : super(key: key);

  @override
  _ForgotPageState createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final usernameController = TextEditingController();
  final answerController = TextEditingController();
  final newPasswordController = TextEditingController();
  String? selectedSecurityQuestion;

  final List<String> securityQuestions = [
    'What is your mother’s maiden name?',
    'What was your first pet’s name?',
    'What was the model of your first car?',
    'In what town was your first job?',
    'What is the name of the school you attended for sixth grade?',
  ];

  void verifyAndUpdatePassword(BuildContext context) async {
    // ⚠️ Replace this with your actual MongoDB lookup and update
    String username = usernameController.text.trim();
    String answer = answerController.text.trim();
    String newPassword = newPasswordController.text.trim();

    if (username.isEmpty || selectedSecurityQuestion == null || answer.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // TODO: Replace with your real MongoDB query/update
    bool success = true; // mock for now

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect details, try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset('assets/images/tinylogo.png',
                  width: 100, height: 100),
              const SizedBox(height: 20),
              MyTextField(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSecurityQuestion,
                hint: const Text("Select a Security Question"),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSecurityQuestion = newValue;
                  });
                },
                items: securityQuestions
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              MyTextField(
                controller: answerController,
                hintText: 'Answer to Security Question',
                obscureText: false,
              ),
              const SizedBox(height: 20),
              MyTextField(
                controller: newPasswordController,
                hintText: 'New Password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              MyButtonForgot(
                onTap: () => verifyAndUpdatePassword(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
