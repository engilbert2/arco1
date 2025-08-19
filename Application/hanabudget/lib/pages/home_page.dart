import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hanabudget/pages/login_page.dart';
import 'package:hanabudget/pages/main_page.dart';
import 'package:hanabudget/data/expense_data.dart';
import 'package:hanabudget/models/expense_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final newExpenseNameController = TextEditingController();
  final newExpenseAmountController = TextEditingController();
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final firstName = prefs.getString('firstName') ?? '';
      final lastName = prefs.getString('lastName') ?? '';
      final username = prefs.getString('username') ?? '';

      if (isLoggedIn) {
        setState(() {
          String fullName = (firstName + " " + lastName).trim();
          if (fullName.isEmpty) {
            fullName = username.isNotEmpty ? username : "User";
          }
          _userName = fullName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _redirectToLogin();
      }
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        _userName = 'User';
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ✅ Clear session

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void addNewExpense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newExpenseNameController,
              decoration: const InputDecoration(hintText: 'Expense Name'),
            ),
            TextField(
              controller: newExpenseAmountController,
              decoration: const InputDecoration(hintText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          MaterialButton(
            onPressed: save,
            child: const Text('Save'),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void save() {
    String expenseName = newExpenseNameController.text;
    String expenseAmount = newExpenseAmountController.text;

    if (expenseName.isNotEmpty && expenseAmount.isNotEmpty) {
      ExpenseItem newExpense = ExpenseItem(
        name: expenseName,
        amount: expenseAmount,
        dateTime: DateTime.now(),
        category: 'General', // ✅ default category
      );

      Provider.of<ExpenseData>(context, listen: false).addNewExpense(newExpense);

      // ✅ clear text fields
      newExpenseNameController.clear();
      newExpenseAmountController.clear();
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
      body: SafeArea(
        child: MainPage(
          username: _userName,
          onAddExpense: addNewExpense, // ✅ pass callback
        ),
      ),
    );
  }
}
