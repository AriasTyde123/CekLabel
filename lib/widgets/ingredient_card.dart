import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../models/risk_level.dart';
import 'risk_badge.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.name,
    required this.category,
    required this.riskLevel,
    required this.description,
    this.matchedKeyword,
    this.onTap,
  });

  final String name;
  final IngredientCategory category;
  final RiskLevel riskLevel;
  final String description;
  final String? matchedKeyword;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = RiskStyle.color(riskLevel);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      if (matchedKeyword != null) ...[
                        const SizedBox(height: 2),
                        Text('Terbaca: "$matchedKeyword"', style: textTheme.bodySmall?.copyWith(color: scheme.outline)),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [RiskBadge(level: riskLevel), CategoryBadge(category: category)],
                      ),
                      const SizedBox(height: 10),
                      Text(description, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
