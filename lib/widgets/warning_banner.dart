import 'package:flutter/material.dart';

import '../models/risk_level.dart';
import 'risk_badge.dart';

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.level, required this.title, required this.message});

  final RiskLevel level;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = RiskStyle.color(level);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(RiskStyle.icon(level), color: color, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(message, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
