import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense_item.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _limitController = TextEditingController();

  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _limitStartDate;
  DateTime? _limitEndDate;
  bool _isRecurring = false;
  bool _isSettingLimit = false;
  final _monthlySalaryController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      if (!expenseProvider.isInitialized) {
        await expenseProvider.initialize();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (expenseProvider.monthlySalary > 0) {
            _monthlySalaryController.text = expenseProvider.monthlySalary.toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50] ?? Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey[700] ?? Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categories = expenseProvider.categories;

    // Check if we're currently in a budget limit period
    final isInLimitPeriod = expenseProvider.isBudgetLimitActive;

    // Calculate total spent in the current limit period
    double totalSpentInPeriod = expenseProvider.totalSpentInLimitPeriod;

    // Check if adding this expense would exceed the limit
    final proposedAmount = double.tryParse(_amountController.text) ?? 0;
    final wouldExceedLimit = expenseProvider.wouldExceedBudgetLimit(proposedAmount);

    return Scaffold(
      backgroundColor: Colors.grey[50] ?? Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Add New Expense',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Show warning if limit would be exceeded
              if (wouldExceedLimit)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50] ?? Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200] ?? Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Warning: This expense would exceed your budget limit of ₱${expenseProvider.budgetLimit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red[700] ?? Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Show info if currently in a limit period
              if (isInLimitPeriod && expenseProvider.budgetLimit > 0)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50] ?? Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200] ?? Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'BUDGET LIMIT ACTIVE',
                            style: TextStyle(
                              color: Colors.blue[700] ?? Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        expenseProvider.limitEndDate != null
                            ? 'Valid until: ${DateFormat('MMM dd, yyyy').format(expenseProvider.limitEndDate!)}'
                            : 'Budget limit is active',
                        style: TextStyle(
                          color: Colors.blue[800] ?? Colors.blue.shade800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: totalSpentInPeriod / expenseProvider.budgetLimit,
                        backgroundColor: Colors.blue[100] ?? Colors.blue.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Spent: ₱${totalSpentInPeriod.toStringAsFixed(2)} of ₱${expenseProvider.budgetLimit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.blue[800] ?? Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Basic Information Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPENSE DETAILS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600] ?? Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Expense Name',
                          labelStyle: TextStyle(color: Colors.grey[700] ?? Colors.grey.shade700),
                          filled: true,
                          fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          prefixIcon: Icon(Icons.shopping_bag, color: Colors.grey[600] ?? Colors.grey.shade600),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(color: Colors.grey[700] ?? Colors.grey.shade700),
                          filled: true,
                          fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          prefixIcon: Icon(Icons.attach_money, color: Colors.grey[600] ?? Colors.grey.shade600),
                          prefixText: '₱ ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: Colors.grey[700] ?? Colors.grey.shade700),
                          filled: true,
                          fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          prefixIcon: Icon(Icons.category, color: Colors.grey[600] ?? Colors.grey.shade600),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _monthlySalaryController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Salary',
                          labelStyle: TextStyle(color: Colors.grey[700] ?? Colors.grey.shade700),
                          filled: true,
                          fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.grey[600] ?? Colors.grey.shade600),
                          prefixText: '₱ ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your monthly salary';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50] ?? Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Icon(Icons.calendar_today, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Recurring Expense Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECURRING EXPENSE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600] ?? Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'This is a recurring expense',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                      ),
                      if (_isRecurring) ...[
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _dueDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50] ?? Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dueDate != null
                                      ? 'Due Date: ${DateFormat('MMM dd, yyyy').format(_dueDate!)}'
                                      : 'Set Due Date',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Icon(Icons.calendar_today, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'BUDGET LIMIT SETTINGS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600] ?? Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Set a budget limit for this expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: _isSettingLimit,
                          onChanged: (value) {
                            setState(() {
                              _isSettingLimit = value;
                              if (!value) {
                                _limitController.clear();
                                _limitStartDate = null;
                                _limitEndDate = null;
                              }
                            });
                          },
                        ),
                        if (_isSettingLimit) ...[
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _limitController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Budget Limit Amount',
                              labelStyle: TextStyle(color: Colors.grey[700] ?? Colors.grey.shade700),
                              filled: true,
                              fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600] ?? Colors.grey.shade600),
                              prefixText: '₱ ',
                            ),
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _limitStartDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _limitStartDate = pickedDate;
                                  // Set end date to one month from start if not set
                                  if (_limitEndDate == null || _limitEndDate!.isBefore(pickedDate)) {
                                    _limitEndDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month + 1,
                                      pickedDate.day,
                                    );
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50] ?? Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _limitStartDate != null
                                        ? 'Start: ${DateFormat('MMM dd, yyyy').format(_limitStartDate!)}'
                                        : 'Set Limit Start Date',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Icon(Icons.calendar_today, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _limitEndDate ?? DateTime.now(),
                                firstDate: _limitStartDate ?? DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _limitEndDate = pickedDate;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50] ?? Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _limitEndDate != null
                                        ? 'End: ${DateFormat('MMM dd, yyyy').format(_limitEndDate!)}'
                                        : 'Set Limit End Date',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Icon(Icons.calendar_today, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Add Expense Button
              ElevatedButton(
                onPressed: wouldExceedLimit ? null : () {
                  if (_formKey.currentState!.validate()) {
                    final newExpense = ExpenseItem(
                      name: _nameController.text,
                      amount: double.parse(_amountController.text),
                      date: _selectedDate,
                      category: _selectedCategory,
                      isRecurring: _isRecurring,
                      dueDate: _dueDate,
                      limit: _limitController.text.isNotEmpty
                          ? double.parse(_limitController.text)
                          : null,
                      limitStartDate: _limitStartDate,
                      limitEndDate: _limitEndDate,
                    );

                    expenseProvider.addExpense(newExpense);

                    // Update monthly salary
                    if (_monthlySalaryController.text.isNotEmpty) {
                      expenseProvider.monthlySalary = double.parse(_monthlySalaryController.text);
                    }

                    // Save limit dates if set
                    if (_isSettingLimit && _limitStartDate != null && _limitEndDate != null && _limitController.text.isNotEmpty) {
                      expenseProvider.setBudgetLimit(
                        double.parse(_limitController.text),
                        _limitStartDate!,
                        _limitEndDate!,
                      );
                    }

                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: wouldExceedLimit ? Colors.grey : Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _limitController.dispose();
    _monthlySalaryController.dispose();
    super.dispose();
  }
}