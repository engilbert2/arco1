import 'package:mongo_dart/mongo_dart.dart';

class MongoDBService {
  static const String _connectionString = 'mongodb+srv://engilbertreyes2:Learnjava12261999%2A@cluster0.warxlph.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0e';
  static const String _databaseName = 'Arcodb';

  late Db _db;
  late DbCollection _usersCollection;
  late DbCollection _expensesCollection;
  late DbCollection _budgetsCollection;

  // Singleton pattern
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

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

  // Connect to MongoDB
  Future<void> connect() async {
    try {
      _db = await Db.create(_connectionString);
      await _db.open();

      // Test the connection
      await _db.serverStatus();

      _usersCollection = _db.collection('users');
      _expensesCollection = _db.collection('expenses');
      _budgetsCollection = _db.collection('budgets');

      print('Connected to MongoDB Atlas successfully');
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      await _db.close();
      rethrow;
    }
  }

  // Close connection
  Future<void> close() async {
    await _db.close();
  }

  // User Operations
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    try {
      var user = await _usersCollection.findOne(where.eq('username', username));
      if (user != null && user['password'].toString() == password) {
        return _processDocument(user);
      }
      return null;
    } catch (e) {
      print('Error authenticating user: $e');
      return null;
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      // Check if user already exists
      var existingUser = await _usersCollection.findOne(where.eq('username', userData['username']));
      if (existingUser != null) {
        return false; // User already exists
      }

      // Ensure all data is in the correct format
      var cleanUserData = {
        'username': userData['username'].toString(),
        'firstName': userData['firstName'].toString(),
        'lastName': userData['lastName'].toString(),
        'email': userData['email']?.toString() ?? '',
        'password': userData['password'].toString(),
        'securityQuestion': userData['securityQuestion']?.toString() ?? '',
        'securityAnswer': userData['securityAnswer']?.toString() ?? '',
        'createdAt': DateTime.now(),
        'isActive': true,
        'role': 'user',
      };

      var result = await _usersCollection.insertOne(cleanUserData);
      return result.isSuccess;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = DateTime.now();
      var result = await _usersCollection.updateOne(
          where.eq('_id', ObjectId.fromHexString(userId)),
          modify.set('firstName', updateData['firstName'])
              .set('lastName', updateData['lastName'])
              .set('email', updateData['email'])
              .set('updatedAt', updateData['updatedAt'])
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
      expenseData['userId'] = ObjectId.fromHexString(userId);
      expenseData['createdAt'] = DateTime.now();
      // Remove manual _id assignment, let MongoDB generate it
      expenseData.remove('_id');

      var result = await _expensesCollection.insertOne(expenseData);
      return result.isSuccess;
    } catch (e) {
      print('Error adding expense: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserExpenses(String userId) async {
    try {
      var expenses = await _expensesCollection
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
      updateData['updatedAt'] = DateTime.now();
      var result = await _expensesCollection.updateOne(
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
      var result = await _expensesCollection.deleteOne(where.eq('_id', ObjectId.fromHexString(expenseId)));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Budget Operations
  Future<bool> setBudget(String userId, Map<String, dynamic> budgetData) async {
    try {
      budgetData['userId'] = ObjectId.fromHexString(userId);
      budgetData['createdAt'] = DateTime.now();
      // Remove manual _id assignment, let MongoDB generate it
      budgetData.remove('_id');

      // Check if budget already exists for this user and month/year
      var existingBudget = await _budgetsCollection.findOne(where
          .eq('userId', ObjectId.fromHexString(userId))
          .eq('month', budgetData['month'])
          .eq('year', budgetData['year']));

      if (existingBudget != null) {
        // Update existing budget
        budgetData['updatedAt'] = DateTime.now();
        var result = await _budgetsCollection.updateOne(
            where.eq('_id', existingBudget['_id']),
            modify.set('amount', budgetData['amount'])
                .set('categories', budgetData['categories'])
                .set('updatedAt', budgetData['updatedAt'])
        );
        return result.isSuccess;
      } else {
        // Create new budget
        var result = await _budgetsCollection.insertOne(budgetData);
        return result.isSuccess;
      }
    } catch (e) {
      print('Error setting budget: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserBudget(String userId, int month, int year) async {
    try {
      var budget = await _budgetsCollection.findOne(where
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
      var users = await _usersCollection.find().toList();
      return users.map((user) => _processDocument(user)).toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Admin Operations - Get all expenses (for admin panel)
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    try {
      var expenses = await _expensesCollection.find().toList();
      return expenses.map((expense) => _processDocument(expense)).toList();
    } catch (e) {
      print('Error fetching all expenses: $e');
      return [];
    }
  }

  // Admin Operations - Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      var totalUsers = await _usersCollection.count();
      var totalExpenses = await _expensesCollection.count();
      var totalBudgets = await _budgetsCollection.count();

      // Get total spending across all users - Fixed aggregation pipeline
      var pipeline = [
        {
          '\$group': {
            '_id': null,
            'totalSpent': {'\$sum': '\$amount'}
          }
        }
      ];

      var aggResult = await _expensesCollection.aggregateToStream(pipeline).toList();
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

  // Additional helper methods for better ObjectId handling
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      var user = await _usersCollection.findOne(where.eq('_id', ObjectId.fromHexString(userId)));
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
      var expense = await _expensesCollection.findOne(where.eq('_id', ObjectId.fromHexString(expenseId)));
      if (expense != null) {
        return _processDocument(expense);
      }
      return null;
    } catch (e) {
      print('Error fetching expense by ID: $e');
      return null;
    }
  }
}