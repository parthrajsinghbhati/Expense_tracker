import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class WeeklyComparison {
  const WeeklyComparison({
    required this.category,
    required this.currentWeekTotal,
    required this.previousWeekTotal,
    required this.percentChange,
  });

  final ExpenseCategory category;
  final double currentWeekTotal;
  final double previousWeekTotal;
  final double percentChange;

  bool get hasPreviousSpend => previousWeekTotal > 0;
}

class ExpenseService {
  ExpenseService();

  // Removed direct Firebase dependencies for local preview

  /*
  CollectionReference<Map<String, dynamic>> get _expensesCollection {
    return _firestore.collection('expenses');
  }

  Future<void> addExpense(Expense expense) async {
    await _expensesCollection.add(expense.toMap());
  }
  */
  Future<void> addExpense(Expense expense) async {}

  Stream<List<Expense>> getExpenses() {
    // Mock data for local preview
    return Stream.value([
      Expense(
        amount: 1200,
        category: ExpenseCategory.travel,
        date: DateTime.now().subtract(const Duration(days: 1)),
        note: 'Taxi to Airport',
      ),
      Expense(
        amount: 450,
        category: ExpenseCategory.food,
        date: DateTime.now(),
        note: 'Lunch',
      ),
      Expense(
        amount: 150,
        category: ExpenseCategory.others,
        date: DateTime.now().subtract(const Duration(days: 2)),
        note: 'Misc items',
      ),
    ]);
  }

  Future<Map<ExpenseCategory, double>> computeCategoryTotals({
    DateTime? start,
    DateTime? end,
  }) async {
    // Mock data for local preview
    return {
      ExpenseCategory.food: 5400.0,
      ExpenseCategory.travel: 2100.0,
      ExpenseCategory.shopping: 3500.0,
      ExpenseCategory.others: 800.0,
    };
  }

  Future<WeeklyComparison> computeWeeklyComparison({
    ExpenseCategory category = ExpenseCategory.food,
  }) async {
    // Mock data for local preview
    return WeeklyComparison(
      category: category,
      currentWeekTotal: 1250.0,
      previousWeekTotal: 1100.0,
      percentChange: 13.6,
    );
  }

  /*
  Future<double> _sumCategoryForRange({
    required ExpenseCategory category,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _expensesCollection
        .where('category', isEqualTo: category.label)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.fold<double>(0, (sum, doc) {
      final amount = doc.data()['amount'];
      return sum + ((amount as num?)?.toDouble() ?? 0);
    });
  }
  */
}
