import 'package:flutter/material.dart';

import '../models/cross_contamination.dart';
import '../models/detected_ingredient.dart';
import '../models/ingredient.dart';
import '../models/profile_impact.dart';
import '../models/risk_level.dart';
import '../models/scan_result.dart';
import '../models/shopping_tips.dart';
import 'home_cards.dart';
import 'profile_avatar.dart';
import 'risk_badge.dart';

const _dangerColor = Color(0xFFEF4444);
const _cautionColor = Color(0xFFF59E0B);
const _safeColor = Color(0xFF10B981);

/// Section 1: Bold Traffic Light status header banner with AI / Offline mode badge.
class TrafficLightBanner extends StatelessWidget {
  const TrafficLightBanner({super.key, required this.summary, this.isOfflineMode = true});

  final ScanSummary summary;
  final bool isOfflineMode;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (summary.overallLevel) {
      RiskLevel.danger => (_dangerColor, Colors.white, Icons.warning_rounded),
      RiskLevel.caution => (_cautionColor, const Color(0xFF1F2937), Icons.error_outline_rounded),
      RiskLevel.safe => (_safeColor, Colors.white, Icons.verified_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      summary.headline,
                      style: TextStyle(
                        color: fg,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        height: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOfflineMode ? Icons.cloud_off_rounded : Icons.auto_awesome_rounded,
                            size: 12,
                            color: fg,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOfflineMode ? 'Mode Offline' : 'Analisis AI',
                            style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  summary.subtitle,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.94),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 2: Product name, brand, edit action, and Safe List bookmark toggle.
class ProductInfoCard extends StatelessWidget {
  const ProductInfoCard({
    super.key,
    required this.result,
    required this.onEdit,
    required this.onToggleSave,
  });

  final ScanResult result;
  final VoidCallback onEdit;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final hasBrand = result.brand.trim().isNotEmpty;
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            result.productName,
                            style: const TextStyle(
                              color: homeInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined, size: 15, color: homeMuted),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasBrand ? result.brand : 'Ketuk untuk ubah nama produk & merek',
                      style: TextStyle(
                        color: hasBrand ? homeMuted : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: hasBrand ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: result.isSaved ? 'Hapus dari Daftar Aman' : 'Simpan ke Daftar Aman',
            onPressed: onToggleSave,
            style: IconButton.styleFrom(
              backgroundColor: result.isSaved ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
              foregroundColor: result.isSaved ? homeGreen : homeMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(result.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
          ),
        ],
      ),
    );
  }
}

/// Section 3: Compact per-family-member risk status rows.
class MultiProfileImpactCard extends StatelessWidget {
  const MultiProfileImpactCard({
    super.key,
    required this.impacts,
    required this.onManageProfiles,
  });

  final List<ProfileImpact> impacts;
  final VoidCallback onManageProfiles;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dampak Profil Keluarga',
                  style: TextStyle(color: homeInk, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: onManageProfiles,
                style: TextButton.styleFrom(
                  foregroundColor: homeGreen,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  impacts.isEmpty ? 'Tambah' : 'Atur',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          if (impacts.isEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Belum ada profil keluarga aktif. Tambahkan profil agar sistem menandai alergen khusus tiap anggota keluarga.',
              style: TextStyle(color: homeMuted, fontSize: 13, height: 1.4),
            ),
          ] else ...[
            const SizedBox(height: 8),
            for (var i = 0; i < impacts.length; i++) ...[
              if (i > 0) const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
              _ImpactRow(impact: impacts[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.impact});

  final ProfileImpact impact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (impact.level) {
      RiskLevel.danger => (const Color(0xFFFEF2F2), const Color(0xFFB91C1C), const Color(0xFFFECACA)),
      RiskLevel.caution => (const Color(0xFFFFFBEB), const Color(0xFF92400E), const Color(0xFFFDE68A)),
      RiskLevel.safe => (const Color(0xFFECFDF5), const Color(0xFF065F46), const Color(0xFFA7F3D0)),
    };

    return Row(
      children: [
        ProfileAvatar(profile: impact.profile, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                impact.profile.name,
                style: const TextStyle(color: homeInk, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              if (impact.profile.role != impact.profile.name)
                Text(
                  impact.profile.role,
                  style: const TextStyle(color: homeMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Text(
              impact.label,
              textAlign: TextAlign.right,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section 4: Soft amber warning card for "may contain" / shared facility statements.
class CrossContaminationAlertCard extends StatelessWidget {
  const CrossContaminationAlertCard({
    super.key,
    required this.crossContamination,
    this.hasSevereImpact = false,
  });

  final CrossContamination crossContamination;
  final bool hasSevereImpact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.priority_high_rounded, color: Color(0xFFB45309), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peringatan Kontaminasi Silang',
                  style: TextStyle(color: Color(0xFF78350F), fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  crossContamination.statement,
                  style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                ),
                if (hasSevereImpact) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Status dinaikkan menjadi Bahaya karena ada profil dengan Alergi Berat.',
                    style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 5: Interactive color-coded ingredient chips with click-to-translate bottom sheet.
class IngredientBreakdownCard extends StatelessWidget {
  const IngredientBreakdownCard({
    super.key,
    required this.ingredients,
    required this.onIngredientTap,
  });

  final List<DetectedIngredient> ingredients;
  final ValueChanged<DetectedIngredient> onIngredientTap;

  static String chipLabel(DetectedIngredient item) {
    final keyword = item.matchedKeyword.trim();
    final name = item.ingredientName.trim();
    if (keyword.isNotEmpty && keyword.toLowerCase() != name.toLowerCase()) {
      return '${_titleCase(keyword)} ($name)';
    }
    if (item.category == IngredientCategory.syubhat) {
      final tag = item.isNonHalal ? 'Non-Halal' : 'Syubhat';
      if (!name.toLowerCase().contains(tag.toLowerCase())) {
        return '$name ($tag)';
      }
    }
    if (item.category == IngredientCategory.sugarAlias && !name.toLowerCase().contains('gula')) {
      return '$name (Gula)';
    }
    if (item.allergenGroup != null && item.allergenGroup!.toLowerCase() != name.toLowerCase()) {
      return '$name (${item.allergenGroup})';
    }
    return name;
  }

  static String _titleCase(String value) => value
      .split(' ')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Analisis Komposisi (Klik untuk arti)',
                  style: TextStyle(color: homeInk, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${ingredients.length} bahan',
                style: const TextStyle(color: homeMuted, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ingredients.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Tidak ada bahan yang dikenali dari teks label. Coba foto ulang dengan pencahayaan lebih jelas.',
                style: TextStyle(color: homeMuted, fontSize: 13, height: 1.4),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in ingredients)
                  _IngredientPill(
                    label: chipLabel(item),
                    level: item.riskLevel,
                    onTap: () => onIngredientTap(item),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _IngredientPill extends StatelessWidget {
  const _IngredientPill({
    required this.label,
    required this.level,
    required this.onTap,
  });

  final String label;
  final RiskLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, dot) = switch (level) {
      RiskLevel.danger => (
          const Color(0xFFFEF2F2),
          const Color(0xFFFCA5A5),
          const Color(0xFF991B1B),
          _dangerColor,
        ),
      RiskLevel.caution => (
          const Color(0xFFFFFBEB),
          const Color(0xFFFCD34D),
          const Color(0xFF92400E),
          _cautionColor,
        ),
      RiskLevel.safe => (
          const Color(0xFFF0FDF4),
          const Color(0xFFBBF7D0),
          const Color(0xFF065F46),
          _safeColor,
        ),
    };

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section 6: Generic Shopping Tips powered by Gemini AI with automatic Offline Fallback.
class ShoppingTipsCard extends StatelessWidget {
  const ShoppingTipsCard({
    super.key,
    required this.tips,
    required this.isLoading,
  });

  final ShoppingTips? tips;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isOffline = tips?.isOffline ?? true;
    return _SectionCard(
      backgroundColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFBBF7D0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: homeGreen, size: 19),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tips Belanja Alternatif',
                  style: TextStyle(color: homeInk, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (tips != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOffline ? const Color(0xFFE2E8F0) : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOffline ? 'Mode Offline' : 'Gemini AI',
                    style: TextStyle(
                      color: isOffline ? const Color(0xFF334155) : const Color(0xFF065F46),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading && tips == null)
            const Row(
              children: [
                SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text(
                  'Menyiapkan tips belanja...',
                  style: TextStyle(color: homeMuted, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            )
          else if (tips != null)
            for (var i = 0; i < tips!.tips.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline_rounded, size: 16, color: homeGreen),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tips!.tips[i],
                      style: const TextStyle(color: Color(0xFF1E3A2F), fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

/// Interactive Bottom Sheet explaining a tapped ingredient in plain Indonesian.
Future<void> showIngredientMeaningSheet(
  BuildContext context, {
  required DetectedIngredient item,
  List<String> aliases = const [],
  VoidCallback? onOpenFullDetail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.ingredientName,
              style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                    color: homeInk,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RiskBadge(level: item.riskLevel),
                CategoryBadge(category: item.category),
                if (item.allergenGroup != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      'Alergen ${item.allergenGroup}',
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            if (item.matchedKeyword.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Tercantum di label sebagai: "${item.matchedKeyword}"',
                style: const TextStyle(color: homeMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Artinya dalam bahasa awam',
              style: TextStyle(color: homeMuted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: const TextStyle(color: homeInk, fontSize: 15, height: 1.5),
            ),
            if (aliases.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Nama lain di kemasan',
                style: TextStyle(color: homeMuted, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final alias in aliases.take(8))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(alias, style: const TextStyle(color: homeInk, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
            if (onOpenFullDetail != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onOpenFullDetail();
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('Buka di Kamus Bahan'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Dialog to edit product name and brand for a saved/scanned result.
Future<({String name, String brand})?> showEditProductInfoDialog(
  BuildContext context, {
  required String initialName,
  required String initialBrand,
}) {
  final nameController = TextEditingController(text: initialName == defaultProductName ? '' : initialName);
  final brandController = TextEditingController(text: initialBrand);
  return showDialog<({String name, String brand})>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Ubah Info Produk'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama produk',
              hintText: 'Mis. Biskuit Cokelat Krim',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: brandController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Merek (opsional)',
              hintText: 'Mis. Sari Gandum',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, (name: nameController.text, brand: brandController.text)),
          child: const Text('Simpan'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    brandController.dispose();
  });
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
    this.borderColor = homeBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

