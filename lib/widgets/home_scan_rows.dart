import 'package:flutter/material.dart';

import '../models/risk_level.dart';
import '../models/scan_result.dart';
import 'home_cards.dart';

class HomeScanRow {
  const HomeScanRow({
    required this.title,
    required this.subtitle,
    required this.risk,
    required this.onTap,
    this.image,
    this.isSaved = false,
  });

  factory HomeScanRow.result(
    ScanResult result, {
    required BuildContext context,
    required RiskLevel risk,
    required VoidCallback onTap,
  }) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final date = result.scannedAt.toLocal();
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: true,
    );
    final timestamp = '${date.day} ${months[date.month - 1]}, $time';
    final subtitle = result.brand.isNotEmpty ? '${result.brand} · $timestamp' : timestamp;
    return HomeScanRow(
      title: result.productName,
      subtitle: subtitle,
      risk: result.totalDetected == 0 ? null : risk,
      isSaved: result.isSaved,
      onTap: onTap,
    );
  }

  final String title;
  final String subtitle;
  final RiskLevel? risk;
  final String? image;
  final bool isSaved;
  final VoidCallback onTap;
}

class HomeScanRows extends StatelessWidget {
  const HomeScanRows({super.key, required this.rows});

  final List<HomeScanRow> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: homeBorder)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0xFFEDF1EF)),
            _ScanTile(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.row});

  final HomeScanRow row;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (row.risk) {
      RiskLevel.safe => (const Color(0xFF08633F), const Color(0xFFE0F7E9)),
      RiskLevel.caution => (const Color(0xFF8C570D), const Color(0xFFFFF0D4)),
      RiskLevel.danger => (const Color(0xFFA9323D), const Color(0xFFFFE7E7)),
      null => (const Color(0xFF42544D), const Color(0xFFEDF1F0)),
    };
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 5, color: color),
          const SizedBox(width: 4),
          Text(row.risk?.label ?? 'Tidak dikenal', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
    final stackBadge = MediaQuery.textScalerOf(context).scale(10) >= 15;
    return InkWell(
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: row.image == null
                  ? const ColoredBox(
                      color: Color(0xFFE3F4EB),
                      child: SizedBox.square(dimension: 41, child: Icon(Icons.receipt_long_rounded, color: homeGreen)),
                    )
                  : Image.asset(row.image!, width: 41, height: 41, fit: BoxFit.cover, excludeFromSemantics: true),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: homeInk, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (row.isSaved) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.bookmark_rounded, size: 13, color: homeGreen),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(row.subtitle, style: const TextStyle(color: homeMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  if (stackBadge) ...[const SizedBox(height: 4), badge],
                ],
              ),
            ),
            if (!stackBadge) ...[const SizedBox(width: 7), badge],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 17, color: homeMuted),
          ],
        ),
      ),
    );
  }
}
