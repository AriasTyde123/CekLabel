import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../models/risk_level.dart';

class RiskStyle {
  static Color color(RiskLevel level) => switch (level) {
        RiskLevel.danger => Colors.red,
        RiskLevel.caution => Colors.orange,
        RiskLevel.safe => Colors.green,
      };

  static IconData icon(RiskLevel level) => switch (level) {
        RiskLevel.danger => Icons.dangerous_rounded,
        RiskLevel.caution => Icons.warning_amber_rounded,
        RiskLevel.safe => Icons.check_circle_rounded,
      };
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final color = RiskStyle.color(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(RiskStyle.icon(level), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            level.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});

  final IngredientCategory category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Text(
        category.label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
      ),
    );
  }
}
