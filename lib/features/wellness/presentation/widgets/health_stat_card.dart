import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// A 2x2-grid metric card: icon, value, label, and an optional goal line.
class HealthStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? goal;

  const HealthStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
          if (goal != null) ...[
            const SizedBox(height: 6),
            Text(goal!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
