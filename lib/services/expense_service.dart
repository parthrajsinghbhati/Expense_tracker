import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

class ExpenseService {
  final CollectionReference<Map<String, dynamic>> _expensesCollection =
      FirebaseFirestore.instance.collection('expenses');

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addExpense(Expense expense) async {
    if (_userId.isEmpty) return;
    
    // Always enforce the current user's ID
    final expenseWithUser = Expense(
      id: expense.id,
      userId: _userId,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      note: expense.note,
    );
    
    await _expensesCollection.add(expenseWithUser.toMap());
  }

  Stream<List<Expense>> getExpenses() {
    if (_userId.isEmpty) return Stream.value([]);

    // Query ONLY by userId to avoid needing a Composite Index!
    // We will do the sorting by date locally in Dart.
    return _expensesCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs.map((doc) {
        return Expense.fromFirestore(doc);
      }).toList();

      // Sort locally: newest first
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    });
  }

  Future<void> deleteExpense(String id) async {
    if (_userId.isEmpty) return;
    await _expensesCollection.doc(id).delete();
  }

  Future<Map<ExpenseCategory, double>> computeTotalsForRange(DateTime? start, DateTime? end) async {
    if (_userId.isEmpty) return {};

    // Query ONLY by userId to avoid needing a Composite Index!
    final snapshot = await _expensesCollection
        .where('userId', isEqualTo: _userId)
        .get();

    final expenses = snapshot.docs.map((doc) {
      return Expense.fromFirestore(doc);
    }).where((e) {
      if (start != null && e.date.isBefore(start)) return false;
      if (end != null && e.date.isAfter(end)) return false;
      return true;
    }).toList();

    final totals = <ExpenseCategory, double>{};
    for (final category in ExpenseCategory.values) {
      totals[category] = 0.0;
    }

    for (final expense in expenses) {
      totals[expense.category] = totals[expense.category]! + expense.amount;
    }

    return totals;
  }

  Future<WeeklyComparison> computeWeeklyComparison({ExpenseCategory? category}) async {
    if (_userId.isEmpty) {
      return WeeklyComparison(
        category: category ?? ExpenseCategory.food,
        currentWeekTotal: 0,
        previousWeekTotal: 0,
        percentChange: 0,
        hasPreviousSpend: false,
      );
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final startOfCurrentWeek = todayMidnight.subtract(Duration(days: now.weekday - 1));
    final startOfPreviousWeek = startOfCurrentWeek.subtract(const Duration(days: 7));

    // Query ONLY by userId to avoid needing a Composite Index!
    final snapshot = await _expensesCollection
        .where('userId', isEqualTo: _userId)
        .get();

    final allExpenses = snapshot.docs.map((doc) {
      return Expense.fromFirestore(doc);
    }).toList();

    double currentTotal = 0;
    double previousTotal = 0;
    bool hasPrevious = false;

    for (final expense in allExpenses) {
      if (category != null && expense.category != category) continue;

      if (expense.date.isAfter(startOfCurrentWeek) || expense.date.isAtSameMomentAs(startOfCurrentWeek)) {
        currentTotal += expense.amount;
      } else if (expense.date.isAfter(startOfPreviousWeek) || expense.date.isAtSameMomentAs(startOfPreviousWeek)) {
        previousTotal += expense.amount;
        hasPrevious = true;
      }
    }

    double percentChange = 0;
    if (previousTotal > 0) {
      percentChange = ((currentTotal - previousTotal) / previousTotal) * 100;
    } else if (currentTotal > 0) {
      percentChange = 100;
    }

    return WeeklyComparison(
      category: category ?? ExpenseCategory.food,
      currentWeekTotal: currentTotal,
      previousWeekTotal: previousTotal,
      percentChange: percentChange,
      hasPreviousSpend: hasPrevious,
    );
  }

  String generateManualInsight(Map<ExpenseCategory, double> currentTotals, Map<ExpenseCategory, double> previousTotals, String timeRangeLabel) {
    if (currentTotals.values.every((amount) => amount == 0)) {
      return "You haven't spent anything during this period! Add some expenses to get insights.";
    }

    final currentSum = currentTotals.values.fold<double>(0, (s, a) => s + a);
    final previousSum = previousTotals.values.fold<double>(0, (s, a) => s + a);

    // 1. Overall Trend
    String trendLine = "";
    if (previousSum > 0) {
      final diff = ((currentSum - previousSum) / previousSum) * 100;
      if (diff > 5) {
        trendLine = "Your spending this $timeRangeLabel is up by ${diff.toStringAsFixed(0)}% compared to the previous period.";
      } else if (diff < -5) {
        trendLine = "Great job! You've spent ${diff.abs().toStringAsFixed(0)}% less this $timeRangeLabel than the previous period.";
      } else {
        trendLine = "Your spending this $timeRangeLabel is consistent with the previous period.";
      }
    } else {
      trendLine = "You spent a total of ₹${currentSum.toStringAsFixed(0)} this $timeRangeLabel.";
    }

    // 2. Highest Category
    final sortedCategories = currentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedCategories.isEmpty) {
      return trendLine;
    }
    
    final topCategory = sortedCategories.first;
    String categoryLine = "";
    if (topCategory.value > 0) {
      categoryLine = " Most of your money (₹${topCategory.value.toStringAsFixed(0)}) went to ${topCategory.key.label}.";
    }

    // 3. Category Shift (if any)
    String shiftLine = "";
    for (final entry in currentTotals.entries) {
      final prevVal = previousTotals[entry.key] ?? 0;
      if (prevVal > 0 && entry.value > prevVal * 1.5) {
        shiftLine = " Watch out: your ${entry.key.label} spending has spiked significantly!";
        break;
      }
    }

    return "$trendLine$categoryLine$shiftLine";
  }
}

class WeeklyComparison {
  final ExpenseCategory category;
  final double currentWeekTotal;
  final double previousWeekTotal;
  final double percentChange;
  final bool hasPreviousSpend;

  WeeklyComparison({
    required this.category,
    required this.currentWeekTotal,
    required this.previousWeekTotal,
    required this.percentChange,
    required this.hasPreviousSpend,
  });
}
