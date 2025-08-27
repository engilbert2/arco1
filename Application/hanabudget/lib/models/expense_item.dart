import 'package:hive/hive.dart';

part 'expense_item.g.dart';

@HiveType(typeId: 0)
class ExpenseItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final bool isRecurring;

  @HiveField(5)
  final DateTime? dueDate;

  @HiveField(6)
  final double? limit;

  @HiveField(7)
  final DateTime? limitStartDate;

  @HiveField(8)
  final DateTime? limitEndDate;

  ExpenseItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    this.isRecurring = false,
    this.dueDate,
    this.limit,
    this.limitStartDate,
    this.limitEndDate,
  });
}