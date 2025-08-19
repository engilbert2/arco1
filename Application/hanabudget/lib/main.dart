import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pages
import 'pages/login_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/forgot_page.dart';
import 'pages/home_page.dart';
import 'pages/graph_page.dart';
import 'pages/expense_adder.dart';

// Data & DB
import 'package:hanabudget/data/expense_data.dart';
import 'package:hanabudget/database/mongo_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _initMongo() async {
    try {
      print('🔄 Initializing MongoDB connection...');
      await MongoDBService().connect();
      print('✅ MongoDB initialization completed in main.dart');
      return true;
    } catch (e) {
      print('❌ Failed to initialize MongoDB in main.dart: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initMongo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 20),
                    Text('Connecting to database...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data != true) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 20),
                    Text('Failed to connect to database'),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild to retry connection
                        (context as Element).markNeedsBuild();
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // MongoDB connected successfully, show the main app
        return ChangeNotifierProvider<ExpenseData>(
          create: (context) => ExpenseData(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mobile Budgeting',
            theme: ThemeData(primarySwatch: Colors.green),
            home: const LoginPage(),
            routes: {
              '/home': (context) => const HomePage(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => SignUpPage(),
              '/forgot': (context) => ForgotPage(),
              '/graph': (context) => const GraphPage(),
              '/addExpense': (context) => const AddExpense(),
            },
          ),
        );
      },
    );
  }
}