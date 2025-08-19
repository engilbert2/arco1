import 'package:flutter/material.dart';
import 'package:hanabudget/data/budget_data.dart';
import 'package:hanabudget/data/expense_data.dart';
import 'package:hanabudget/models/budget_item.dart' as budget;
import 'package:hanabudget/models/expense_item.dart' as expense;
import 'package:hanabudget/pages/budget_creator.dart';
import 'package:provider/provider.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState(); // Fixed class name
}

class _BudgetPageState extends State<BudgetPage> { // Fixed class name
  double progress(String category) {
    List<expense.ExpenseItem> expenses =
        Provider.of<ExpenseData>(context).overallExpenseList;

    List<expense.ExpenseItem> specificExpenses = [];
    double amount = 0.0;

    // Filter expenses by category
    for (var i = 0; i < expenses.length; i++) {
      if (expenses[i].category == category) {
        specificExpenses.add(expenses[i]);
      }
    }

    // Calculate total amount for the category
    for (expense.ExpenseItem expenseItem in specificExpenses) {
      amount += double.tryParse(expenseItem.amount) ?? 0.0; // Fixed: use += and tryParse
    }

    // Get budget limit for the category
    double budgetAmount = double.tryParse(budgetLimit(category)) ?? 100.0;

    if (budgetAmount <= 0.0) {
      return 0.0;
    } else {
      double progressValue = amount / budgetAmount;
      return progressValue > 1.0 ? 1.0 : progressValue; // Cap at 1.0 (100%)
    }
  }

  String specificTotal(String category) {
    List<expense.ExpenseItem> expenses =
        Provider.of<ExpenseData>(context).overallExpenseList;

    List<expense.ExpenseItem> specificExpenses = [];
    double amount = 0.0;

    // Filter expenses by category
    for (var i = 0; i < expenses.length; i++) {
      if (expenses[i].category == category) {
        specificExpenses.add(expenses[i]);
      }
    }

    // Calculate total amount for the category
    for (expense.ExpenseItem expenseItem in specificExpenses) {
      amount += double.tryParse(expenseItem.amount) ?? 0.0; // Fixed: use += and tryParse
    }

    String amountString = amount.toStringAsFixed(2);
    return amountString;
  }

  String budgetLimit(String category) {
    List<budget.BudgetItem> budgets = Provider.of<BudgetData>(context).budgetList;

    // Handle empty budget list
    if (budgets.isEmpty) {
      return "100.00"; // Default budget limit
    }

    budget.BudgetItem? specificCategory; // Made nullable

    // Find the specific category budget
    for (var i = 0; i < budgets.length; i++) {
      if (budgets[i].category == category) {
        specificCategory = budgets[i];
        break; // Exit loop once found
      }
    }

    // Return the budget amount or default if not found
    return specificCategory?.amount ?? "100.00";
  }

  // Helper method to get progress bar color based on usage
  Color getProgressColor(String category) {
    double progressValue = progress(category);
    if (progressValue >= 1.0) {
      return Colors.red; // Over budget
    } else if (progressValue >= 0.8) {
      return Colors.orange; // Close to budget
    } else {
      return const Color(0xFF1ED891); // Within budget
    }
  }

  // Helper method to build budget row
  Widget buildBudgetRow(String category) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "\t$category",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "\$${specificTotal(category)} / \$${budgetLimit(category)}\t",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          backgroundColor: Colors.grey[300],
          color: getProgressColor(category),
          value: progress(category),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetCreator()),
          );
        },
        backgroundColor: const Color(0xFF1ED891),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView( // Added to prevent overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 200),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Budget Overview",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budget categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  buildBudgetRow("Food"),
                  buildBudgetRow("Transportation"),
                  buildBudgetRow("Utilities"),
                  buildBudgetRow("Entertainment"),
                  buildBudgetRow("Health"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}