import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/category_breakdown_bar.dart';
import '../widgets/empty_state.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _expenseService = ExpenseService();
  late Future<_InsightData> _insightFuture;

  @override
  void initState() {
    super.initState();
    _insightFuture = _loadInsights();
  }

  Future<_InsightData> _loadInsights() async {
    final categoryTotals = await _expenseService.computeCategoryTotals();
    final weeklyComparison = await _expenseService.computeWeeklyComparison();
    return _InsightData(
      categoryTotals: categoryTotals,
      weeklyComparison: weeklyComparison,
    );
  }

  Future<void> _refresh() async {
    setState(() => _insightFuture = _loadInsights());
    await _insightFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    return FutureBuilder<_InsightData>(
      future: _insightFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load insights',
            message: snapshot.error.toString(),
          );
        }

        final data = snapshot.data!;
        final totalSpending = data.categoryTotals.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Insights',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current month spending',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalSpending),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (totalSpending == 0)
                        const EmptyState.compact(
                          icon: Icons.bar_chart_outlined,
                          title: 'No spending this month',
                          message: 'Your breakdown appears after expenses are added.',
                        )
                      else
                        for (final entry in data.categoryTotals.entries)
                          CategoryBreakdownBar(
                            category: entry.key,
                            amount: entry.value,
                            total: totalSpending,
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _buildSmartInsight(data.weeklyComparison),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildSmartInsight(WeeklyComparison comparison) {
    final category = comparison.category.label;
    final change = comparison.percentChange.abs().toStringAsFixed(0);

    if (!comparison.hasPreviousSpend && comparison.currentWeekTotal > 0) {
      return 'You started spending on $category this week. Keep an eye on it as the week grows.';
    }

    if (comparison.percentChange > 0) {
      return 'You spent $change% more on $category this week compared to last week.';
    }

    if (comparison.percentChange < 0) {
      return 'You spent $change% less on $category this week compared to last week.';
    }

    return 'Your $category spending is steady compared to last week.';
  }
}

class _InsightData {
  const _InsightData({
    required this.categoryTotals,
    required this.weeklyComparison,
  });

  final Map<ExpenseCategory, double> categoryTotals;
  final WeeklyComparison weeklyComparison;
}
