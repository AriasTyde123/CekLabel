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
    this.userAllergenGroup,
    this.onTap,
  });

  final String name;
  final IngredientCategory category;
  final RiskLevel riskLevel;
  final String description;
  final String? matchedKeyword;
  final String? userAllergenGroup;
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          if (userAllergenGroup != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'Alergen Anda ($userAllergenGroup)',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
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
