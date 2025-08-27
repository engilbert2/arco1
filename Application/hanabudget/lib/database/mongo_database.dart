import 'package:mongo_dart/mongo_dart.dart';
import 'dart:math';

class MongoDBService {
  // Move credentials to a separate config file or environment variables
  // For development, you can keep it here, but for production, use secure storage
  static const String _connectionString = 'mongodb+srv://engilbertreyes2:Learnjava12261999%2A@cluster0.warxlph.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';
  static const String _databaseName = 'Arcodb';

  // Make these nullable initially and check before use
  static Db? _db;
  static DbCollection? _usersCollection;
  static DbCollection? _expensesCollection;
  static DbCollection? _budgetsCollection;
  static DbCollection? _verificationTokensCollection;

  // Add a flag to track initialization
  static bool _isInitialized = false;

  // Singleton pattern
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  // Getter methods with safety checks
  static DbCollection get usersCollection {
    if (_usersCollection == null) {
      throw StateError('MongoDB collections not initialized. Call connect() first.');
    }
    return _usersCollection!;
  }

  static DbCollection get expensesCollection {
    if (_expensesCollection == null) {
      throw StateError('MongoDB collections not initialized. Call connect() first.');
    }
    return _expensesCollection!;
  }

  static DbCollection get budgetsCollection {
    if (_budgetsCollection == null) {
      throw StateError('MongoDB collections not initialized. Call connect() first.');
    }
    return _budgetsCollection!;
  }

  // Add to the getter methods
  static DbCollection get verificationTokensCollection {
    if (_verificationTokensCollection == null) {
      throw StateError('MongoDB collections not initialized. Call connect() first.');
    }
    return _verificationTokensCollection!;
  }

  // Helper method to convert ObjectId to String safely
  String _objectIdToString(dynamic id) {
    if (id is ObjectId) {
      return id.toHexString();
    } else if (id is String) {
      return id;
    }
    return id.toString();
  }

  // Helper method to convert documents for API consumption
  Map<String, dynamic> _processDocument(Map<String, dynamic> doc) {
    if (doc.containsKey('_id')) {
      doc['id'] = _objectIdToString(doc['_id']);
      // Keep _id as string for consistency
      doc['_id'] = _objectIdToString(doc['_id']);
    }
    if (doc.containsKey('userId') && doc['userId'] is ObjectId) {
      doc['userId'] = _objectIdToString(doc['userId']);
    }
    return doc;
  }

  // Connect to MongoDB with retry logic
  Future<MongoDBService> connect() async {
    if (_isInitialized && _db != null && _db!.isConnected) {
      print('✅ MongoDB already connected');
      return this;
    }

    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        print('🔄 Attempting MongoDB connection (attempt ${currentRetry + 1}/$maxRetries)');

        _db = await Db.create(_connectionString);
        await _db!.open();

        // Test the connection with timeout
        await _db!.serverStatus().timeout(const Duration(seconds: 10));
        print('✅ Database connection established');

        // ✅ Initialize collections AFTER successful connection
        _usersCollection = _db!.collection('users');
        _expensesCollection = _db!.collection('expenses');
        _budgetsCollection = _db!.collection('budgets');
        // Add to the connect() method after initializing other collections
        _verificationTokensCollection = _db!.collection('verification_tokens');

        print('✅ Collections initialized: users, expenses, budgets, verification_tokens');
        _isInitialized = true;

        print('✅ Connected to MongoDB Atlas successfully');
        return this;
      } catch (e) {
        currentRetry++;
        print('❌ Connection attempt $currentRetry failed: $e');

        if (currentRetry >= maxRetries) {
          print('❌ Max connection attempts reached. Connection failed.');
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: 2 * currentRetry));
      }
    }
    throw Exception("Failed to connect to MongoDB after multiple retries.");
  }

  // Method to ensure connection before operations
  Future<void> _ensureConnected() async {
    if (!_isInitialized || _db == null || !_db!.isConnected) {
      print('⚠️ Database not properly connected, reconnecting...');
      await connect();
    }
  }

  // Close connection
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _isInitialized = false;
      _usersCollection = null;
      _expensesCollection = null;
      _budgetsCollection = null;
      _verificationTokensCollection = null;
    }
  }

  // Add to MongoDBService class
  Future<bool> is2FAEnabled(String userId) async {
    try {
      await _ensureConnected();
      var user = await usersCollection.findOne(
          where.eq('_id', ObjectId.fromHexString(userId))
      );

      return user != null && user['is2FAEnabled'] == true;
    } catch (e) {
      print('Error checking 2FA status: $e');
      return false;
    }
  }

  // Add these methods to the MongoDBService class
  // Generate and store a verification token
  Future<String> generateVerificationToken(String userId, String email) async {
    try {
      await _ensureConnected();

      // Generate a 6-digit code
      String token = (100000 + Random().nextInt(900000)).toString();
      int expiresAt = DateTime.now().add(Duration(minutes: 15)).millisecondsSinceEpoch;

      // Remove any existing tokens for this user
      await verificationTokensCollection.deleteMany(
          where.eq('userId', ObjectId.fromHexString(userId))
      );

      // Store the new token
      await verificationTokensCollection.insertOne({
        'userId': ObjectId.fromHexString(userId),
        'token': token,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now(),
      });

      return token;
    } catch (e) {
      print('Error generating verification token: $e');
      throw Exception('Failed to generate verification token');
    }
  }

  // Verify a token
  Future<bool> verifyToken(String userId, String token) async {
    try {
      await _ensureConnected();

      var tokenRecord = await verificationTokensCollection.findOne(
          where.eq('userId', ObjectId.fromHexString(userId))
              .eq('token', token)
              .gt('expiresAt', DateTime.now().millisecondsSinceEpoch)
      );

      if (tokenRecord != null) {
        // Delete the token after successful verification
        await verificationTokensCollection.deleteOne(
            where.eq('_id', tokenRecord['_id'])
        );
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying token: $e');
      return false;
    }
  }

  // Update the authenticateUser method to check 2FA status
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    try {
      await _ensureConnected();
      var user = await usersCollection.findOne(where.eq('username', username));
      if (user != null && user['password'].toString() == password) {
        // Check if 2FA is enabled
        bool is2FAEnabled = user['is2FAEnabled'] == true;
        var processedUser = _processDocument(user);
        processedUser['is2FAEnabled'] = is2FAEnabled;
        return processedUser;
      }
      return null;
    } catch (e) {
      print('Error authenticating user: $e');
      return null;
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      await _ensureConnected();
      print('✅ Database connection verified for user creation');

      // Debug: Print the username being checked
      print('Checking if username exists: ${userData['username']}');

      // Check if user already exists (case-insensitive and trimmed)
      String username = userData['username'].toString().trim().toLowerCase();
      var existingUser = await usersCollection.findOne(
          where.eq('username', RegExp('^${RegExp.escape(username)}\$', caseSensitive: false))
      );

      // Debug: Print result of user check
      print('Existing user found: ${existingUser != null}');

      if (existingUser != null) {
        print('User already exists with username: ${existingUser['username']}');
        return false; // User already exists
      }

      // Also check by email if provided
      if (userData['email'] != null && userData['email'].toString().trim().isNotEmpty) {
        String email = userData['email'].toString().trim().toLowerCase();
        var existingEmail = await usersCollection.findOne(
            where.eq('email', RegExp('^${RegExp.escape(email)}\$', caseSensitive: false))
        );

        if (existingEmail != null) {
          print('User already exists with email: ${existingEmail['email']}');
          return false; // Email already exists
        }
      }

      // Ensure all data is in the correct format
      // In the createUser method in mongo_database.dart, update the cleanUserData
      var cleanUserData = {
        'username': username, // Use the cleaned username
        'firstName': userData['firstName'].toString().trim(),
        'lastName': userData['lastName'].toString().trim(),
        'email': userData['email']?.toString().trim().toLowerCase() ?? '',
        'password': userData['password'].toString(),
        'securityQuestion': userData['securityQuestion']?.toString() ?? '',
        'securityAnswer': userData['securityAnswer']?.toString() ?? '',
        'createdAt': DateTime.now(),
        'isActive': true,
        'role': 'user',
        'is2FAEnabled': false, // Default to disabled
      };

      print('Creating user with data: ${cleanUserData['username']}');
      var result = await usersCollection.insertOne(cleanUserData);

      print('User creation result: ${result.isSuccess}');
      return result.isSuccess;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      await _ensureConnected();
      updateData['updatedAt'] = DateTime.now();
      var result = await usersCollection.updateOne(
          where.eq('_id', ObjectId.fromHexString(userId)),
          modify.set('firstName', updateData['firstName'])
              .set('lastName', updateData['lastName'])
              .set('email', updateData['email'])
              .set('updatedAt', updateData['updatedAt'])
              .set('is2FAEnabled', updateData['is2FAEnabled'] ?? false) // Add 2FA update
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Expense Operations
  Future<bool> addExpense(String userId, Map<String, dynamic> expenseData) async {
    try {
      await _ensureConnected();
      expenseData['userId'] = ObjectId.fromHexString(userId);
      expenseData['createdAt'] = DateTime.now();
      // Remove manual _id assignment, let MongoDB generate it
      expenseData.remove('_id');

      var result = await expensesCollection.insertOne(expenseData);
      return result.isSuccess;
    } catch (e) {
      print('Error adding expense: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserExpenses(String userId) async {
    try {
      await _ensureConnected();
      var expenses = await expensesCollection
          .find(where.eq('userId', ObjectId.fromHexString(userId)))
          .toList();
      // Process each expense to convert ObjectIds to Strings
      return expenses.map((expense) => _processDocument(expense)).toList();
    } catch (e) {
      print('Error fetching user expenses: $e');
      return [];
    }
  }

  Future<bool> updateExpense(String expenseId, Map<String, dynamic> updateData) async {
    try {
      await _ensureConnected();
      updateData['updatedAt'] = DateTime.now();
      var result = await expensesCollection.updateOne(
          where.eq('_id', ObjectId.fromHexString(expenseId)),
          modify.set('amount', updateData['amount'])
              .set('category', updateData['category'])
              .set('description', updateData['description'])
              .set('date', updateData['date'])
              .set('updatedAt', updateData['updatedAt'])
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _ensureConnected();
      var result = await expensesCollection.deleteOne(where.eq('_id', ObjectId.fromHexString(expenseId)));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Budget Operations
  Future<bool> setBudget(String userId, Map<String, dynamic> budgetData) async {
    try {
      await _ensureConnected();
      budgetData['userId'] = ObjectId.fromHexString(userId);
      budgetData['createdAt'] = DateTime.now();
      // Remove manual _id assignment, let MongoDB generate it
      budgetData.remove('_id');

      // Check if budget already exists for this user and month/year
      var existingBudget = await budgetsCollection.findOne(where
          .eq('userId', ObjectId.fromHexString(userId))
          .eq('month', budgetData['month'])
          .eq('year', budgetData['year']));

      if (existingBudget != null) {
        // Update existing budget
        budgetData['updatedAt'] = DateTime.now();
        var result = await budgetsCollection.updateOne(
            where.eq('_id', existingBudget['_id']),
            modify.set('amount', budgetData['amount'])
                .set('categories', budgetData['categories'])
                .set('updatedAt', budgetData['updatedAt'])
        );
        return result.isSuccess;
      } else {
        // Create new budget
        var result = await budgetsCollection.insertOne(budgetData);
        return result.isSuccess;
      }
    } catch (e) {
      print('Error setting budget: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserBudget(String userId, int month, int year) async {
    try {
      await _ensureConnected();
      var budget = await budgetsCollection.findOne(where
          .eq('userId', ObjectId.fromHexString(userId))
          .eq('month', month)
          .eq('year', year));

      if (budget != null) {
        return _processDocument(budget);
      }
      return null;
    } catch (e) {
      print('Error fetching user budget: $e');
      return null;
    }
  }

  // Admin Operations - Get all users (for admin panel)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      await _ensureConnected();
      var users = await usersCollection.find().toList();
      return users.map((user) => _processDocument(user)).toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Admin Operations - Get all expenses (for admin panel)
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    try {
      await _ensureConnected();
      var expenses = await expensesCollection.find().toList();
      return expenses.map((expense) => _processDocument(expense)).toList();
    } catch (e) {
      print('Error fetching all expenses: $e');
      return [];
    }
  }

  // Admin Operations - Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      await _ensureConnected();
      var totalUsers = await usersCollection.count();
      var totalExpenses = await expensesCollection.count();
      var totalBudgets = await budgetsCollection.count();

      // Get total spending across all users - Fixed aggregation pipeline
      var pipeline = [
        {
          '\$group': {
            '_id': null,
            'totalSpent': {'\$sum': '\$amount'}
          }
        }
      ];

      var aggResult = await expensesCollection.aggregateToStream(pipeline).toList();
      var totalSpent = aggResult.isNotEmpty ?
      (aggResult.first['totalSpent'] ?? 0).toDouble() : 0.0;

      return {
        'totalUsers': totalUsers,
        'totalExpenses': totalExpenses,
        'totalBudgets': totalBudgets,
        'totalSpent': totalSpent,
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      print('Error fetching user statistics: $e');
      return {};
    }
  }

  // Debug method to check all usernames in database
  Future<List<String>> getAllUsernames() async {
    try {
      await _ensureConnected();
      var users = await usersCollection.find().toList();
      return users.map((user) => user['username'].toString()).toList();
    } catch (e) {
      print('Error fetching usernames: $e');
      return [];
    }
  }

  // Additional helper methods for better ObjectId handling
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      await _ensureConnected();
      var user = await usersCollection.findOne(where.eq('_id', ObjectId.fromHexString(userId)));
      if (user != null) {
        return _processDocument(user);
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getExpenseById(String expenseId) async {
    try {
      await _ensureConnected();
      var expense = await expensesCollection.findOne(where.eq('_id', ObjectId.fromHexString(expenseId)));
      if (expense != null) {
        return _processDocument(expense);
      }
      return null;
    } catch (e) {
      print('Error fetching expense by ID: $e');
      return null;
    }
  }

  // Add to MongoDBService class
  Future<bool> toggle2FA(String userId, bool enable) async {
    try {
      await _ensureConnected();
      var result = await usersCollection.updateOne(
          where.eq('_id', ObjectId.fromHexString(userId)),
          modify.set('is2FAEnabled', enable)
              .set('updatedAt', DateTime.now())
      );
      return result.isSuccess;
    } catch (e) {
      print('Error toggling 2FA: $e');
      return false;
    }
  }
}