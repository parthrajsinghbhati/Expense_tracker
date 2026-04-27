import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
  });

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: _categoryColor(expense.category).withOpacity(0.14),
          child: Icon(
            _categoryIcon(expense.category),
            color: _categoryColor(expense.category),
          ),
        ),
        title: Text(
          expense.category.label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              DateFormat.jm().format(expense.date),
              if (expense.note != null && expense.note!.isNotEmpty)
                expense.note!,
            ].join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Text(
          currencyFormat.format(expense.amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.food => Icons.restaurant_outlined,
      ExpenseCategory.travel => Icons.flight_takeoff_outlined,
      ExpenseCategory.shopping => Icons.shopping_bag_outlined,
      ExpenseCategory.others => Icons.more_horiz,
    };
  }

  Color _categoryColor(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.food => const Color(0xFF2E7D32),
      ExpenseCategory.travel => const Color(0xFF1565C0),
      ExpenseCategory.shopping => const Color(0xFFAD4E00),
      ExpenseCategory.others => const Color(0xFF6A4C93),
    };
  }
}
