// budget_item.dart - Updated for MongoDB
class BudgetItem {
  final String? id; // MongoDB ObjectId
  final String amount;
  final String category;
  final String? userId; // Link to user

  BudgetItem({
    this.id,
    required this.amount,
    required this.category,
    this.userId,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['_id']?.toString(),
      amount: json['amount'],
      category: json['category'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'amount': amount,
      'category': category,
    };

    if (id != null) data['_id'] = id;
    if (userId != null) data['userId'] = userId;

    return data;
  }
}

// expense_item.dart - Updated for MongoDB
class ExpenseItem {
  final String? id; // MongoDB ObjectId
  final String name;
  final String amount;
  final DateTime dateTime;
  final String category;
  final String? userId; // Link to user

  ExpenseItem({
    this.id,
    required this.name,
    required this.amount,
    required this.dateTime,
    required this.category,
    this.userId,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: json['_id']?.toString(),
      name: json['name'],
      amount: json['amount'],
      dateTime: DateTime.parse(json['dateTime']),
      category: json['category'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
    };

    if (id != null) data['_id'] = id;
    if (userId != null) data['userId'] = userId;

    return data;
  }
}