import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load expenses',
            message: snapshot.error.toString(),
          );
        }

        final expenses = snapshot.data ?? [];
        if (expenses.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            message: 'Add your first expense to start seeing insights.',
          );
        }

        final groupedExpenses = _groupByDate(expenses);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Expenses',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            for (final entry in groupedExpenses.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
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
