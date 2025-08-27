import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense_item.dart';
import '../models/category_item.dart';

class ExpenseProvider with ChangeNotifier {
  late Box<ExpenseItem> _expensesBox;
  late Box<CategoryItem> _categoriesBox;
  late Box _settingsBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<ExpenseItem> get expenses => _isInitialized ? _expensesBox.values.toList() : [];
  List<CategoryItem> get categories => _isInitialized ? _categoriesBox.values.toList() : [];

  double _monthlySalary = 0;
  double get monthlySalary => _monthlySalary;

  DateTime? _limitStartDate;
  DateTime? _limitEndDate;
  double _budgetLimit = 0;

  DateTime? get limitStartDate => _limitStartDate;
  DateTime? get limitEndDate => _limitEndDate;
  double get budgetLimit => _budgetLimit;

  Future<void> initialize() async {
    try {
      _expensesBox = await Hive.openBox<ExpenseItem>('expenses');
      _categoriesBox = await Hive.openBox<CategoryItem>('categories');
      _settingsBox = await Hive.openBox('settings');

      _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing ExpenseProvider: $e');
      // If there's a schema mismatch, try with different box names
      try {
        await Hive.deleteBoxFromDisk('expenses');
        await Hive.deleteBoxFromDisk('categories');

        _expensesBox = await Hive.openBox<ExpenseItem>('expenses_v2');
        _categoriesBox = await Hive.openBox<CategoryItem>('categories_v2');
        _settingsBox = await Hive.openBox('settings');

        _loadSettings();
        _isInitialized = true;
        notifyListeners();
      } catch (e2) {
        print('Second initialization attempt also failed: $e2');
        // Initialize with empty boxes
        _isInitialized = true;
        notifyListeners();
      }
    }
  }

  void _loadSettings() {
    try {
      _monthlySalary = _settingsBox.get('monthlySalary', defaultValue: 0.0);
      _budgetLimit = _settingsBox.get('budgetLimit', defaultValue: 0.0);

      final startMillis = _settingsBox.get('limitStartDate');
      final endMillis = _settingsBox.get('limitEndDate');

      if (startMillis != null) _limitStartDate = DateTime.fromMillisecondsSinceEpoch(startMillis);
      if (endMillis != null) _limitEndDate = DateTime.fromMillisecondsSinceEpoch(endMillis);
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  void _saveSettings() {
    try {
      _settingsBox.put('monthlySalary', _monthlySalary);
      _settingsBox.put('budgetLimit', _budgetLimit);

      if (_limitStartDate != null) {
        _settingsBox.put('limitStartDate', _limitStartDate!.millisecondsSinceEpoch);
      }

      if (_limitEndDate != null) {
        _settingsBox.put('limitEndDate', _limitEndDate!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  set monthlySalary(double value) {
    _monthlySalary = value;
    _saveSettings();
    notifyListeners();
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double get remainingBudget {
    return _monthlySalary - totalExpenses;
  }

  // Check if current date is within budget limit period
  bool get isBudgetLimitActive {
    if (!_isInitialized) return false;

    final now = DateTime.now();
    return _limitStartDate != null &&
        _limitEndDate != null &&
        now.isAfter(_limitStartDate!) &&
        now.isBefore(_limitEndDate!);
  }

  // Get total expenses during the current budget limit period
  double get totalSpentInLimitPeriod {
    if (!isBudgetLimitActive) return 0;

    return expenses
        .where((expense) =>
    expense.date.isAfter(_limitStartDate!) &&
        expense.date.isBefore(_limitEndDate!))
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Check if adding an amount would exceed the budget limit
  bool wouldExceedBudgetLimit(double amount) {
    return isBudgetLimitActive &&
        _budgetLimit > 0 &&
        (totalSpentInLimitPeriod + amount) > _budgetLimit;
  }

  // Set budget limit with dates
  void setBudgetLimit(double limit, DateTime startDate, DateTime endDate) {
    _budgetLimit = limit;
    _limitStartDate = startDate;
    _limitEndDate = endDate;
    _saveSettings();
    notifyListeners();
  }

  // Clear budget limit
  void clearBudgetLimit() {
    _budgetLimit = 0;
    _limitStartDate = null;
    _limitEndDate = null;
    _saveSettings();
    notifyListeners();
  }

  void addExpense(ExpenseItem expense) {
    if (!_isInitialized) return;

    _expensesBox.add(expense);
    notifyListeners();
  }

  void addCategory(CategoryItem category) {
    if (!_isInitialized) return;

    _categoriesBox.add(category);
    notifyListeners();
  }

  void deleteExpense(int index) {
    if (!_isInitialized) return;

    _expensesBox.deleteAt(index);
    notifyListeners();
  }

  void deleteCategory(int index) {
    if (!_isInitialized) return;

    _categoriesBox.deleteAt(index);
    notifyListeners();
  }

  List<ExpenseItem> getExpensesForMonth(DateTime month) {
    if (!_isInitialized) return [];

    return expenses.where((expense) {
      return expense.date.year == month.year && expense.date.month == month.month;
    }).toList();
  }

  double getCategoryTotal(String categoryName) {
    if (!_isInitialized) return 0;

    return expenses
        .where((expense) => expense.category == categoryName)
        .fold(0, (sum, expense) => sum + expense.amount);
  }
}