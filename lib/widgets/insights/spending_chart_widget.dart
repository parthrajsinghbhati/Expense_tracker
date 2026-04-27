import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../empty_state.dart';

class SpendingChartWidget extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalSpending;
  final NumberFormat currencyFormat;

  const SpendingChartWidget({
    super.key,
    required this.categoryTotals,
    required this.totalSpending,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B7280).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Text(
            'Total Spending',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalSpending),
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 32),
          if (totalSpending == 0)
            const EmptyState.compact(
              icon: Icons.pie_chart_rounded,
              title: 'No spending yet',
              message: 'Add expenses to see your chart.',
            )
          else ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: categoryTotals.entries.map((entry) {
                    final percentage = (entry.value / totalSpending) * 100;
                    return PieChartSectionData(
                      color: _categoryColor(entry.key),
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 30,
                      titleStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: categoryTotals.entries.map((entry) {
                if (entry.value == 0) return const SizedBox.shrink();
                return _buildLegendItem(entry.key, entry.value, currencyFormat);
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLegendItem(ExpenseCategory category, double amount, NumberFormat format) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _categoryColor(category),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
            Text(
              format.format(amount),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _categoryColor(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.food => const Color(0xFF10B981), // Emerald
      ExpenseCategory.travel => const Color(0xFF3B82F6), // Blue
      ExpenseCategory.shopping => const Color(0xFFF59E0B), // Amber
      ExpenseCategory.others => const Color(0xFF8B5CF6), // Violet
    };
  }
}
