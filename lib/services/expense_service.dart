import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
      return Expense.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
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

  Future<String> generateGroqInsight(Map<ExpenseCategory, double> currentTotals, Map<ExpenseCategory, double> previousTotals, String timeRangeLabel) async {
    final groqApiKey = dotenv.env['GROQ_API_KEY'];
    if (groqApiKey == null || groqApiKey.isEmpty || groqApiKey == "YOUR_GROQ_API_KEY_HERE") {
      return "Please add your Groq API key in the .env file to see AI insights!";
    }

    if (currentTotals.values.every((amount) => amount == 0)) {
      return "You haven't spent anything during this period! Add some expenses to get AI insights.";
    }

    final currentContext = currentTotals.entries
        .where((e) => e.value > 0)
        .map((e) => "${e.key.label}: ₹${e.value.toStringAsFixed(0)}")
        .join(", ");

    final previousContext = previousTotals.entries
        .where((e) => e.value > 0)
        .map((e) => "${e.key.label}: ₹${e.value.toStringAsFixed(0)}")
        .join(", ");

    String prompt;
    if (timeRangeLabel == "All Time") {
      prompt = "Act as a smart, friendly financial advisor. My TOTAL all-time spending is: $currentContext. Give me a punchy, 2-line insight. In line 1, give a general observation. In line 2, compare my spending *between different categories* (e.g., what I'm spending most on vs least on). Keep it brief, no intro or outro.";
    } else {
      prompt = "Act as a smart, friendly financial advisor. My spending THIS $timeRangeLabel is: $currentContext. My spending LAST $timeRangeLabel was: ${previousContext.isEmpty ? '₹0' : previousContext}. Give me a punchy, 2-line insight. In line 1, compare my current $timeRangeLabel vs previous $timeRangeLabel spending. In line 2, compare my spending *between different categories* this $timeRangeLabel (e.g., what I'm spending most on). Keep it brief, no intro or outro.";
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return "Groq Error: ${errorData['error']['message'] ?? 'Unknown'}";
        } catch (_) {
          return "Groq Error ${response.statusCode}: ${response.body}";
        }
      }
    } catch (e) {
      return "Error connecting to AI: $e";
    }
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
