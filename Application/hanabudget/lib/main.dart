import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Config
import 'config/flutter_dotenv.dart';

// Models
import 'package:hanabudget/models/expense_item.dart';
import 'package:hanabudget/models/category_item.dart';

// Providers
import 'package:hanabudget/providers/expense_provider.dart';

// Services
import 'package:hanabudget/services/auth_service.dart';
import 'package:hanabudget/database/mongo_database.dart';

// Screens
import 'package:hanabudget/screens/home_screen.dart';
import 'package:hanabudget/screens/expense_screen.dart';
import 'package:hanabudget/screens/records_screen.dart';
import 'package:hanabudget/screens/category_screen.dart';
import 'package:hanabudget/screens/captcha_screen.dart';
import 'package:hanabudget/screens/two_fa_settings.dart';

// Pages (Authentication)
import 'package:hanabudget/pages/login_page.dart';
import 'package:hanabudget/pages/sign_up_page.dart';
import 'package:hanabudget/pages/forgot_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: Environment.fileName);
    print('✅ Environment file loaded: ${Environment.fileName}');

    // Debug environment variables (remove in production)
    if (!kReleaseMode) {
      print('🔧 Debug - EMAIL_USER: ${Environment.emailUser.isNotEmpty ? "Set" : "Not set"}');
      print('🔧 Debug - EMAIL_PASSWORD: ${Environment.emailPassword.isNotEmpty ? "Set" : "Not set"}');
    }

    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Clear existing boxes to avoid schema mismatch
    try {
      await Hive.deleteBoxFromDisk('expenses');
      await Hive.deleteBoxFromDisk('categories');
      await Hive.deleteBoxFromDisk('settings');
    } catch (e) {
      print('No existing boxes to delete or error deleting: $e');
    }

    // Register Hive adapters
    Hive.registerAdapter(ExpenseItemAdapter());
    Hive.registerAdapter(CategoryItemAdapter());

    // Open Hive boxes
    await Hive.openBox<ExpenseItem>('expenses');
    await Hive.openBox<CategoryItem>('categories');
    await Hive.openBox('settings');

    print('✅ Hive initialized successfully');

    runApp(const MyApp());
  } catch (e) {
    print('⚠️ Warning: Could not load .env file or initialize Hive: $e');
    print('Some functionality may not work properly');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ExpenseProvider(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'Hana Budget',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: FutureBuilder(
          future: AuthService().isUserLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const InitializationScreen();
            } else if (snapshot.hasData && snapshot.data == true) {
              return HomeScreen();
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/initialization': (context) => const InitializationScreen(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/forgot': (context) => const ForgotPage(),
          '/home': (context) => HomeScreen(),
          '/expense': (context) => ExpenseScreen(),
          '/records': (context) => RecordsScreen(),
          '/category': (context) => CategoryScreen(),
          '/2fa-settings': (context) => TwoFASettingsScreen(),
          '/captcha': (context) {
            final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return CaptchaScreen(userData: userData ?? {});
          },
        },
        onUnknownRoute: (settings) {
          print('⚠️ Unknown route: ${settings.name}');
          return MaterialPageRoute(builder: (context) => const LoginPage());
        },
      ),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _hiveInitialized = false;
  bool _mongoInitialized = false;
  bool _providerInitialized = false;
  String _statusMessage = 'Starting initialization...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusMessage = 'Initializing local storage...';
      });

      // Initialize the ExpenseProvider
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.initialize();

      setState(() {
        _hiveInitialized = true;
        _providerInitialized = true;
        _statusMessage = 'Local storage initialized successfully';
      });
      print('✅ ExpenseProvider initialized successfully');

      // Initialize MongoDB (don't block the app if it fails)
      await _initializeMongoDB();
    } catch (e) {
      print('❌ Failed to initialize ExpenseProvider: $e');
      setState(() {
        _statusMessage = 'Error initializing app: $e';
      });

      // Still navigate to login page even if initialization fails
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _initializeMongoDB() async {
    try {
      setState(() {
        _statusMessage = 'Connecting to database...';
      });

      print('🔄 Initializing MongoDB connection...');
      await MongoDBService().connect();

      setState(() {
        _mongoInitialized = true;
        _statusMessage = 'Database connected successfully';
      });
      print('✅ MongoDB initialization completed');
    } catch (e) {
      print('❌ Failed to initialize MongoDB: $e');
      setState(() {
        _mongoInitialized = false;
        _statusMessage = 'Database connection failed - continuing offline';
      });
    } finally {
      // Navigate to the appropriate screen after initialization attempts
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _providerInitialized) {
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final isLoggedIn = await AuthService().isUserLoggedIn();
      if (mounted) {
        if (isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.green,
                  );
                },
              ),
              const SizedBox(height: 32),

              // App name
              Text(
                'Hana Budget',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),

              // Status message
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Status indicators
              Column(
                children: [
                  _buildStatusRow(
                    'Local Storage',
                    _hiveInitialized,
                    Icons.storage,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'App Provider',
                    _providerInitialized,
                    Icons.settings,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Database Connection',
                    _mongoInitialized,
                    Icons.cloud,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isComplete, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: isComplete ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isComplete ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        if (isComplete)
          const Icon(Icons.check_circle, size: 16, color: Colors.green)
        else
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}