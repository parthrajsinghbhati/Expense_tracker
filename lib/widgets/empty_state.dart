import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  }) : isCompact = false;

  const EmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  }) : isCompact = true;

  final IconData icon;
  final String title;
  final String message;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: isCompact ? 36 : 52,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: isCompact ? 10 : 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: content,
      ),
    );
  }
}
