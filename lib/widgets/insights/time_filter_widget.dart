import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/insights_screen.dart';

class TimeFilterWidget extends StatelessWidget {
  final TimeFilter currentFilter;
  final ValueChanged<TimeFilter> onFilterChanged;

  const TimeFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: TimeFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          final label = switch (filter) {
            TimeFilter.allTime => 'All Time',
            TimeFilter.monthly => 'Monthly',
            TimeFilter.weekly => 'Weekly',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
