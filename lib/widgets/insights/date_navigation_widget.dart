import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../screens/insights_screen.dart';

class DateNavigationWidget extends StatelessWidget {
  final TimeFilter currentFilter;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const DateNavigationWidget({
    super.key,
    required this.currentFilter,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (currentFilter == TimeFilter.allTime) return const SizedBox.shrink();

    String dateLabel = "";
    bool canGoForward = false;
    final now = DateTime.now();

    if (currentFilter == TimeFilter.monthly) {
      dateLabel = DateFormat('MMMM yyyy').format(selectedDate);
      canGoForward = selectedDate.year < now.year || (selectedDate.year == now.year && selectedDate.month < now.month);
    } else {
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final startFormat = DateFormat('MMM d').format(startOfWeek);
      final endFormat = DateFormat('MMM d').format(endOfWeek);
      dateLabel = "$startFormat - $endFormat";
      
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      canGoForward = startOfWeek.isBefore(currentWeekStart);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF6B7280),
          ),
          Text(
            dateLabel,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          IconButton(
            onPressed: canGoForward ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: canGoForward ? const Color(0xFF6B7280) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
