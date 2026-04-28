import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/insights/time_filter_widget.dart';
import '../widgets/insights/date_navigation_widget.dart';
import '../widgets/insights/smart_insight_card.dart';
import '../widgets/insights/spending_chart_widget.dart';

enum TimeFilter { allTime, monthly, weekly }

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _expenseService = ExpenseService();
  late Future<_InsightData> _insightFuture;

  TimeFilter _currentFilter = TimeFilter.weekly;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _insightFuture = _loadInsights();
  }

  Future<_InsightData> _loadInsights() async {
    DateTime? currentStart;
    DateTime? currentEnd;
    DateTime? previousStart;
    DateTime? previousEnd;
    String timeRangeLabel = "All Time";

    final nowMidnight = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (_currentFilter == TimeFilter.weekly) {
      currentStart = nowMidnight.subtract(Duration(days: nowMidnight.weekday - 1));
      currentEnd = currentStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      previousStart = currentStart.subtract(const Duration(days: 7));
      previousEnd = currentEnd.subtract(const Duration(days: 7));
      timeRangeLabel = "week";
    } else if (_currentFilter == TimeFilter.monthly) {
      currentStart = DateTime(_selectedDate.year, _selectedDate.month, 1);
      currentEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
      previousStart = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      previousEnd = DateTime(_selectedDate.year, _selectedDate.month, 0, 23, 59, 59);
      timeRangeLabel = "month";
    }

    try {
      final categoryTotals = await _expenseService.computeTotalsForRange(currentStart, currentEnd);
      final previousTotals = await _expenseService.computeTotalsForRange(previousStart, previousEnd);
      final manualInsight = _expenseService.generateManualInsight(categoryTotals, previousTotals, timeRangeLabel);

      return _InsightData(
        categoryTotals: categoryTotals,
        manualInsight: manualInsight,
      );
    } catch (e, stack) {
      debugPrint('Error loading insights: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    
    final newFuture = _loadInsights();
    setState(() {
      _insightFuture = newFuture;
    });
    
    try {
      await newFuture;
    } catch (_) {
      // Error is handled by FutureBuilder in the UI
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.error_outline_rounded,
            title: 'Could not load insights',
            message: 'Make sure your Firestore database is created.',
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
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
            children: [
              TimeFilterWidget(
                currentFilter: _currentFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _currentFilter = filter;
                    _selectedDate = DateTime.now();
                  });
                  _refresh();
                },
              ),
              DateNavigationWidget(
                currentFilter: _currentFilter,
                selectedDate: _selectedDate,
                onPrevious: () {
                  setState(() {
                    if (_currentFilter == TimeFilter.monthly) {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                    } else {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    }
                  });
                  _refresh();
                },
                onNext: () {
                  setState(() {
                    if (_currentFilter == TimeFilter.monthly) {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                    } else {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                    }
                  });
                  _refresh();
                },
              ),
              SmartInsightCard(insight: data.manualInsight),
              const SizedBox(height: 32),
              SpendingChartWidget(
                categoryTotals: data.categoryTotals,
                totalSpending: totalSpending,
                currencyFormat: currencyFormat,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightData {
  const _InsightData({
    required this.categoryTotals,
    required this.manualInsight,
  });

  final Map<ExpenseCategory, double> categoryTotals;
  final String manualInsight;
}
