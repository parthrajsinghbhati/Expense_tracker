import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _expenseService = ExpenseService();

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final grouped = <String, List<Expense>>{};

    for (final expense in expenses) {
      final key = DateFormat.yMMMd().format(expense.date);
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load expenses',
            message: 'Make sure your Firestore database is created.',
          );
        }

        final expenses = snapshot.data ?? [];
        if (expenses.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No expenses yet',
            message: 'Add your first expense to start seeing insights.',
          );
        }

        final groupedExpenses = _groupByDate(expenses);

        return ListView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${expenses.length} Total',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (final entry in groupedExpenses.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  entry.key,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final expense in entry.value) ExpenseCard(expense: expense),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
