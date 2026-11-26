import 'package:flutter/material.dart';

const homeInk = Color(0xFF12261E);
const homeMuted = Color(0xFF52675E);
const homeGreen = Color(0xFF087452);
const homeAccent = Color(0xFF10B981);
const homeBorder = Color(0xFFE1EBE6);

class HomeProfileChip extends StatelessWidget {
  const HomeProfileChip({
    super.key,
    required this.title,
    required this.detail,
    required this.onTap,
    this.image,
  });

  final String title;
  final String detail;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1FAF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFCEE9DC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFD9F5E6),
                backgroundImage: image == null ? null : AssetImage(image!),
                child: image == null ? const Icon(Icons.person_outline_rounded, size: 17, color: homeGreen) : null,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 128),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: homeInk),
                    ),
                    Text(detail, style: const TextStyle(fontSize: 10, color: homeMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const CircleAvatar(
                radius: 8,
                backgroundColor: Color(0xFF0D855F),
                child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScanHero extends StatelessWidget {
  const HomeScanHero({super.key, required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final showArt = MediaQuery.textScalerOf(context).scale(12) < 16;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const RadialGradient(
          center: Alignment(.9, -.8),
          radius: 1.15,
          colors: [Color(0xFF1B7557), Color(0xFF11523F), Color(0xFF0C382D)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x29104B33), blurRadius: 21, offset: Offset(0, 8))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            if (showArt)
              Positioned(
                right: 5,
                top: 2,
                width: (constraints.maxWidth * .48).clamp(100.0, 188.0).toDouble(),
                child: Image.asset('assets/home/scanner.png', excludeFromSemantics: true),
              ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x1388F0BA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x4D94EAC1)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFBBFFDA)),
                          SizedBox(width: 5),
                          Text(
                            'PEMINDAI CERDAS',
                            style: TextStyle(
                              color: Color(0xFFBBFFDA), fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cek label,\nlebih tenang.',
                    style: TextStyle(
                      color: Colors.white, fontSize: 30, height: 1.07, letterSpacing: -1.4, fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Deteksi alergen & gula\ntersembunyi instan',
                    style: TextStyle(color: Color(0xFFCBECDF), fontSize: 12, height: 1.45, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 13),
                  FilledButton(
                    onPressed: onScan,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6DF2B7),
                      foregroundColor: const Color(0xFF073D2D),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 21),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text('Scan Komposisi Makanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeQuickCard extends StatelessWidget {
  const HomeQuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emergency = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emergency;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: homeBorder)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: emergency ? const Color(0xFFFDE9E8) : const Color(0xFFDDF7E9),
                    ),
                    child: Icon(icon, size: 19, color: emergency ? const Color(0xFFB54E52) : homeGreen),
                  ),
                  const Icon(Icons.arrow_outward_rounded, size: 17, color: homeMuted),
                ],
              ),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(color: homeInk, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: homeMuted, fontWeight: FontWeight.w600, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

enum HomeTab { home, history, safeList, profile }

class HomeNav extends StatelessWidget {
  const HomeNav({
    super.key,
    this.currentTab = HomeTab.home,
    required this.onHome,
    required this.onHistory,
    required this.onScan,
    required this.onSafe,
    required this.onProfile,
  });

  final HomeTab currentTab;
  final VoidCallback onHome;
  final VoidCallback onHistory;
  final VoidCallback onScan;
  final VoidCallback onSafe;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Material(
            color: Colors.white,
            child: DecoratedBox(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: homeBorder))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  child: Row(
                    children: [
                      _tab(
                        'Beranda',
                        currentTab == HomeTab.home ? Icons.home_rounded : Icons.home_outlined,
                        onHome,
                        selected: currentTab == HomeTab.home,
                      ),
                      _tab(
                        'Riwayat',
                        Icons.history_rounded,
                        onHistory,
                        selected: currentTab == HomeTab.history,
                      ),
                      const Expanded(child: SizedBox()),
                      _tab(
                        'Daftar Aman',
                        currentTab == HomeTab.safeList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        onSafe,
                        selected: currentTab == HomeTab.safeList,
                      ),
                      _tab(
                        'Profil',
                        currentTab == HomeTab.profile ? Icons.person_rounded : Icons.person_outline_rounded,
                        onProfile,
                        selected: currentTab == HomeTab.profile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox.square(
          dimension: 57,
          child: FloatingActionButton(
            heroTag: null,
            tooltip: 'Pindai label',
            backgroundColor: homeAccent,
            foregroundColor: const Color(0xFF073D2D),
            elevation: 3,
            shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 4)),
            onPressed: onScan,
            child: const Icon(Icons.qr_code_scanner_rounded, size: 25),
          ),
        ),
      ],
    );
  }

  Widget _tab(String label, IconData icon, VoidCallback action, {bool selected = false}) {
    final color = selected ? homeGreen : homeMuted;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 27,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFDDF7E9) : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
