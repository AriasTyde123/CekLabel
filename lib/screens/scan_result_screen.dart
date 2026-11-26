import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../models/scan_result.dart';
import '../models/shopping_tips.dart';
import '../providers/dictionary_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/shopping_tip_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/home_cards.dart';
import '../widgets/scan_result_sections.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.result});

  final ScanResult? result;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  String? _requestedTipKey;

  void _ensureTipsLoaded(TipRequest request) {
    if (_requestedTipKey == request.cacheKey) return;
    _requestedTipKey = request.cacheKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ShoppingTipProvider>().load(request);
    });
  }

  Future<void> _editProduct(ScanResult current) async {
    final scanProvider = context.read<ScanProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final updated = await showEditProductInfoDialog(
      context,
      initialName: current.productName,
      initialBrand: current.brand,
    );
    if (updated == null) return;
    final ok = await scanProvider.updateProductInfo(
      current.id,
      productName: updated.name,
      brand: updated.brand,
    );
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Info produk diperbarui' : (scanProvider.storageError ?? 'Gagal menyimpan perubahan.')),
    ));
  }

  Future<void> _toggleSave(ScanResult current) async {
    final scanProvider = context.read<ScanProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final willSave = !current.isSaved;
    final ok = await scanProvider.toggleSaved(current.id);
    messenger.showSnackBar(SnackBar(
      content: Text(
        ok
            ? (willSave ? 'Disimpan ke Daftar Aman' : 'Dihapus dari Daftar Aman')
            : (scanProvider.storageError ?? 'Gagal memperbarui Daftar Aman.'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.result;
    if (initial == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, title: const Text('Hasil Pindaian')),
        body: const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Belum ada hasil pindaian',
          message: 'Pindai label komposisi terlebih dahulu.',
        ),
      );
    }

    final scanProvider = context.watch<ScanProvider>();
    context.watch<ProfileProvider>();
    final dictionary = context.watch<DictionaryProvider>();
    final tipProvider = context.watch<ShoppingTipProvider>();

    final data = scanProvider.findById(initial.id) ?? initial;
    final summary = scanProvider.summarize(data);
    final tipRequest = TipRequest.fromSummary(data, summary);
    _ensureTipsLoaded(tipRequest);

    final tips = tipProvider.tipsFor(tipRequest);
    final isLoadingTips = tipProvider.isLoading(tipRequest);
    final hasSevereCross = summary.impacts.any(
      (impact) => impact.level == RiskLevel.danger && impact.reasons.any((r) => r.startsWith('Kontaminasi')),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Hasil Analisis', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                TrafficLightBanner(summary: summary, isOfflineMode: data.isOfflineMode),
                const SizedBox(height: 14),
                ProductInfoCard(
                  result: data,
                  onEdit: () => _editProduct(data),
                  onToggleSave: () => _toggleSave(data),
                ),
                const SizedBox(height: 14),
                MultiProfileImpactCard(
                  impacts: summary.impacts,
                  onManageProfiles: () => Navigator.pushNamed(
                    context,
                    summary.impacts.isEmpty ? AppRoutes.profileForm : AppRoutes.preferences,
                  ),
                ),
                if (summary.crossContamination != null) ...[
                  const SizedBox(height: 14),
                  CrossContaminationAlertCard(
                    crossContamination: summary.crossContamination!,
                    hasSevereImpact: hasSevereCross,
                  ),
                ],
                const SizedBox(height: 14),
                IngredientBreakdownCard(
                  ingredients: summary.ingredients,
                  onIngredientTap: (item) {
                    final full = dictionary.findById(item.ingredientId);
                    showIngredientMeaningSheet(
                      context,
                      item: item,
                      aliases: full?.aliases ?? const [],
                      onOpenFullDetail: full == null
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                AppRoutes.dictionaryDetail,
                                arguments: item.ingredientId,
                              ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                ShoppingTipsCard(tips: tips, isLoading: isLoadingTips),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: homeBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    title: const Text(
                      'Lihat Teks Asli Label',
                      style: TextStyle(color: homeInk, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    shape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedAlignment: Alignment.centerLeft,
                    children: [
                      SelectableText(
                        data.rawText,
                        style: const TextStyle(color: homeMuted, fontSize: 12.5, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Pindai Label Lain'),
                  style: FilledButton.styleFrom(
                    backgroundColor: homeGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
