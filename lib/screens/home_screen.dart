import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../providers/dictionary_provider.dart';
import '../providers/preference_provider.dart';
import '../providers/scan_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/home_cards.dart';
import '../widgets/home_scan_rows.dart';
import '../widgets/loading_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSelectTab, this.scrollController});

  final ValueChanged<HomeTab>? onSelectTab;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final preference = context.watch<PreferenceProvider>();
    final scan = context.watch<ScanProvider>();

    if (dictionary.status == DictionaryStatus.loading || dictionary.status == DictionaryStatus.initial) {
      return const Scaffold(body: LoadingIndicator(message: 'Memuat kamus bahan...'));
    }
    if (dictionary.status == DictionaryStatus.error) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: dictionary.errorMessage ?? 'Gagal memuat kamus bahan.',
          actionLabel: 'Coba Lagi',
          onAction: () => context.read<DictionaryProvider>().load(),
        ),
      );
    }

    final name = preference.savedUserName;
    final allergens = preference.savedAllergens;
    final activeScrollController = scrollController ?? PrimaryScrollController.maybeOf(context);
    final history = scan.history;
    void open(String route) => Navigator.pushNamed(context, route);
    void editProfile() => onSelectTab != null ? onSelectTab!(HomeTab.profile) : open(AppRoutes.preferences);
    void startScan() => open(AppRoutes.scan);
    void openSafe() => onSelectTab != null ? onSelectTab!(HomeTab.safeList) : open(AppRoutes.safeList);
    void openHistory() => onSelectTab != null ? onSelectTab!(HomeTab.history) : open(AppRoutes.history);
    void exampleProfile() => _showPanel(
          context,
          icon: Icons.group_outlined,
          title: 'Profil keluarga contoh',
          message: 'Anak dan Ayah adalah contoh tampilan. Pemindaian hanya memakai alergen dari profil yang Anda atur.',
          onEdit: editProfile,
        );
    void exampleScan() => _showPanel(
          context,
          icon: Icons.science_outlined,
          title: 'Contoh hasil pindai',
          message: 'Produk dan status ini hanya ilustrasi, bukan hasil pemindaian atau rekomendasi keamanan pangan.',
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              controller: scrollController,
              primary: scrollController == null,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 17, color: homeGreen),
                              SizedBox(width: 6),
                              Text(
                                'CEKLABEL',
                                style: TextStyle(
                                  color: homeGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Halo, ${name.isEmpty ? 'Bunda' : name}!',
                            style: const TextStyle(
                              color: homeInk, fontSize: 31, height: 1.16, fontWeight: FontWeight.w800, letterSpacing: -1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.outlined(
                      tooltip: 'Notifikasi',
                      onPressed: () => _showPanel(
                        context,
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        message: 'Belum ada notifikasi baru.',
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: homeInk,
                        side: const BorderSide(color: homeBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: _SectionTitle('Profil Keluarga')),
                    const SizedBox(width: 6),
                    _CaptionTag(name.isEmpty ? 'Contoh profil' : '1 profil aktif'),
                  ],
                ),
                const SizedBox(height: 9),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (name.isEmpty) ...[
                        HomeProfileChip(
                          title: 'Anak',
                          detail: 'Alergi Susu',
                          image: 'assets/home/child.png',
                          onTap: exampleProfile,
                        ),
                        const SizedBox(width: 7),
                        HomeProfileChip(
                          title: 'Ayah',
                          detail: 'Rendah Gula',
                          image: 'assets/home/father.png',
                          onTap: exampleProfile,
                        ),
                      ] else
                        HomeProfileChip(title: name, detail: '${allergens.length} alergen', onTap: editProfile),
                      const SizedBox(width: 7),
                      OutlinedButton.icon(
                        onPressed: editProfile,
                        icon: Icon(name.isEmpty ? Icons.add_rounded : Icons.edit_outlined, size: 17),
                        label: Text(name.isEmpty ? 'Tambah' : 'Atur'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: homeGreen,
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: const BorderSide(color: Color(0xFFB9D8CB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                HomeScanHero(onScan: startScan),
                const SizedBox(height: 17),
                const _SectionTitle('Akses Cepat'),
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: HomeQuickCard(
                          icon: Icons.bookmark_rounded,
                          title: 'Daftar Aman',
                          subtitle: 'Hasil cek berisiko rendah',
                          onTap: openSafe,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HomeQuickCard(
                          icon: Icons.medical_services_rounded,
                          title: 'Kartu Darurat Alergi',
                          subtitle: 'Info alergi siap ditunjukkan',
                          emergency: true,
                          onTap: () => _showPanel(
                            context,
                            icon: Icons.medical_services_outlined,
                            title: 'Kartu Darurat Alergi',
                            message: allergens.isEmpty
                                ? 'Tambahkan nama dan alergen di preferensi untuk mengisi kartu ini.'
                                : 'Tunjukkan informasi ini kepada orang yang membantu atau petugas kesehatan.',
                            details: allergens.isEmpty ? null : '$name\nAlergen: ${allergens.join(', ')}',
                            onEdit: editProfile,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 5,
                        runSpacing: 3,
                        children: [
                          const _SectionTitle('Pindaian Terakhir'),
                          if (history.isEmpty) const _CaptionTag('Contoh'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: openHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: homeGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                      child: const Row(
                        children: [Text('Lihat semua'), Icon(Icons.chevron_right_rounded, size: 15)],
                      ),
                    ),
                  ],
                ),
                HomeScanRows(
                  rows: history.isEmpty
                      ? [
                          HomeScanRow(
                            title: 'Oat Gulung Organik',
                            subtitle: 'Hari ini, 09.42',
                            risk: RiskLevel.safe,
                            image: 'assets/home/oats.webp',
                            onTap: exampleScan,
                          ),
                          HomeScanRow(
                            title: 'Biskuit Kelapa',
                            subtitle: 'Kemarin, 17.20',
                            risk: RiskLevel.caution,
                            image: 'assets/home/biscuits.webp',
                            onTap: exampleScan,
                          ),
                          HomeScanRow(
                            title: 'Susu Cokelat Kemasan',
                            subtitle: 'Kemarin, 14.08',
                            risk: RiskLevel.danger,
                            image: 'assets/home/milk.webp',
                            onTap: exampleScan,
                          ),
                        ]
                      : [
                          for (final result in history.take(3))
                            HomeScanRow.result(
                              result,
                              context: context,
                              risk: scan.summarize(result).overallLevel,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.scanResult, arguments: result),
                            ),
                        ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: onSelectTab != null
          ? null
          : HomeNav(
              onHome: () {
                if (activeScrollController != null && activeScrollController.hasClients) {
                  activeScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  );
                }
              },
              onHistory: openHistory,
              onScan: startScan,
              onSafe: openSafe,
              onProfile: editProfile,
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: homeInk, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.4),
      );
}

class _CaptionTag extends StatelessWidget {
  const _CaptionTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE9F4EE), borderRadius: BorderRadius.circular(6)),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(color: Color(0xFF47705E), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .45),
        ),
      );
}

void _showPanel(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String? details,
  VoidCallback? onEdit,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: homeGreen),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: const Color(0xFFFDE9E8),
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(details, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5)),
                  ),
                ),
              ),
            ],
            if (onEdit != null) ...[
              const SizedBox(height: 15),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onEdit();
                },
                child: const Text('Atur preferensi'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
