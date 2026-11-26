import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/family_profile.dart';
import '../providers/profile_provider.dart';
import '../routes.dart';
import '../widgets/profile_avatar.dart';

enum EmergencyLanguage { id, en }

const _emergencyRed = Color(0xFFB91C1C);
const _emergencyDarkRed = Color(0xFF7F1D1D);
const _emergencyInk = Color(0xFF111827);
const _emergencyMuted = Color(0xFF374151);

class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  EmergencyLanguage _lang = EmergencyLanguage.id;
  String? _selectedProfileId;

  bool get _isEn => _lang == EmergencyLanguage.en;

  String _translateAllergen(String allergen) {
    if (!_isEn) return allergen;
    return switch (allergen) {
      'Kacang' => 'Peanuts / Nuts',
      'Susu' => 'Milk / Dairy',
      'Gluten' => 'Gluten / Wheat',
      'Telur' => 'Eggs',
      'Udang' => 'Shrimp / Shellfish',
      'Kedelai' => 'Soy',
      _ => allergen,
    };
  }

  String _translateRole(String role) {
    if (!_isEn) return role;
    return switch (role) {
      'Saya' => 'Me',
      'Anak' => 'Child',
      'Ayah' => 'Father',
      'Ibu' => 'Mother',
      'Kakek' => 'Grandfather',
      'Nenek' => 'Grandmother',
      _ => 'Family Member',
    };
  }

  String _buildPlainText(List<FamilyProfile> visibleProfiles) {
    final buffer = StringBuffer();
    buffer.writeln(_isEn ? 'EMERGENCY ALLERGY CARD (CekLabel)' : 'KARTU DARURAT ALERGI (CekLabel)');
    buffer.writeln(
      _isEn
          ? 'Please read carefully before preparing or serving food.'
          : 'Harap baca dengan saksama sebelum menyiapkan atau menyajikan makanan.',
    );
    for (final profile in visibleProfiles) {
      buffer.writeln();
      final role = _translateRole(profile.role);
      buffer.writeln('- ${profile.name} ($role)');
      if (profile.allergens.isNotEmpty) {
        final allergens = profile.orderedAllergens.map(_translateAllergen).join(', ');
        final level = profile.isSevere
            ? (_isEn ? 'SEVERE ALLERGY / ANAPHYLAXIS RISK' : 'ALERGI BERAT / RISIKO ANAFILAKSIS')
            : (_isEn ? 'MILD INTOLERANCE' : 'INTOLERANSI RINGAN');
        buffer.writeln('  ${_isEn ? 'Allergens' : 'Alergen'}: $allergens');
        buffer.writeln('  ${_isEn ? 'Severity' : 'Tingkat'}: $level');
      }
      final notes = _dietaryNotes(profile);
      if (notes.isNotEmpty) {
        buffer.writeln('  ${_isEn ? 'Additional notes' : 'Catatan tambahan'}: ${notes.join(', ')}');
      }
    }
    return buffer.toString().trim();
  }

  List<String> _dietaryNotes(FamilyProfile profile) => [
        if (profile.avoidHiddenSugar) _isEn ? 'Avoid hidden sugars' : 'Hindari gula tersembunyi',
        if (profile.avoidAdditives) _isEn ? 'Avoid MSG & artificial coloring' : 'Hindari MSG & pewarna sintetis',
      ];

  Future<void> _copyCard(List<FamilyProfile> visibleProfiles) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _buildPlainText(visibleProfiles)));
    messenger.showSnackBar(SnackBar(
      content: Text(_isEn ? 'Emergency card text copied' : 'Teks kartu darurat disalin'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final activeProfiles = profileProvider.activeProfiles;
    final allergyProfiles = activeProfiles.where((p) => p.hasAnyFilter).toList();

    final selectedId = allergyProfiles.any((p) => p.id == _selectedProfileId) ? _selectedProfileId : null;
    final visibleProfiles = selectedId == null
        ? allergyProfiles
        : allergyProfiles.where((p) => p.id == selectedId).toList();
    final hasAnySevere = visibleProfiles.any((p) => p.isSevere && p.allergens.isNotEmpty);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF2F2),
        appBar: AppBar(
          backgroundColor: _emergencyRed,
          foregroundColor: Colors.white,
          surfaceTintColor: _emergencyRed,
          title: Text(
            _isEn ? 'Emergency Allergy Card' : 'Kartu Darurat Alergi',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LanguageToggle(
                language: _lang,
                onChanged: (next) => setState(() => _lang = next),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  _EmergencyHeader(isEn: _isEn, hasSevere: hasAnySevere),
                  const SizedBox(height: 16),
                  if (allergyProfiles.isEmpty)
                    _EmptyEmergencyCard(
                      isEn: _isEn,
                      hasAnyProfiles: profileProvider.profiles.isNotEmpty,
                      onManage: () => Navigator.pushNamed(
                        context,
                        profileProvider.profiles.isEmpty ? AppRoutes.profileForm : AppRoutes.preferences,
                      ),
                    )
                  else ...[
                    if (allergyProfiles.length > 1) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                _isEn ? 'All (${allergyProfiles.length})' : 'Semua (${allergyProfiles.length})',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              selected: selectedId == null,
                              onSelected: (_) => setState(() => _selectedProfileId = null),
                            ),
                            for (final profile in allergyProfiles) ...[
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                selected: selectedId == profile.id,
                                onSelected: (_) => setState(() => _selectedProfileId = profile.id),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    for (var i = 0; i < visibleProfiles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _ProfileEmergencyCard(
                        profile: visibleProfiles[i],
                        isEn: _isEn,
                        roleLabel: _translateRole(visibleProfiles[i].role),
                        translatedAllergens: visibleProfiles[i].orderedAllergens.map(_translateAllergen).toList(),
                        dietaryNotes: _dietaryNotes(visibleProfiles[i]),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _copyCard(visibleProfiles),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(_isEn ? 'Copy Card Text' : 'Salin Teks Kartu'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _emergencyInk,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.preferences),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(_isEn ? 'Edit' : 'Atur'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _emergencyInk,
                            minimumSize: const Size(0, 50),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.language, required this.onChanged});

  final EmergencyLanguage language;
  final ValueChanged<EmergencyLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _emergencyDarkRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(EmergencyLanguage.id, 'ID'),
          _option(EmergencyLanguage.en, 'EN'),
        ],
      ),
    );
  }

  Widget _option(EmergencyLanguage value, String label) {
    final selected = language == value;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _emergencyDarkRed : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyHeader extends StatelessWidget {
  const _EmergencyHeader({required this.isEn, required this.hasSevere});

  final bool isEn;
  final bool hasSevere;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _emergencyRed,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33B91C1C), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEn ? 'FOOD ALLERGY ALERT' : 'PERINGATAN ALERGI MAKANAN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isEn
                ? 'Please read carefully before preparing or serving any food or drink.'
                : 'Harap baca dengan saksama sebelum menyiapkan atau menyajikan makanan/minuman.',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _headerTag(
                icon: Icons.offline_bolt_rounded,
                label: isEn ? '100% Offline Ready' : 'Tersedia 100% Offline',
              ),
              if (hasSevere)
                _headerTag(
                  icon: Icons.warning_amber_rounded,
                  label: isEn ? 'Contains Anaphylaxis Risk' : 'Ada Risiko Anafilaksis',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerTag({required IconData icon, required String label}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _emergencyDarkRed,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _ProfileEmergencyCard extends StatelessWidget {
  const _ProfileEmergencyCard({
    required this.profile,
    required this.isEn,
    required this.roleLabel,
    required this.translatedAllergens,
    required this.dietaryNotes,
  });

  final FamilyProfile profile;
  final bool isEn;
  final String roleLabel;
  final List<String> translatedAllergens;
  final List<String> dietaryNotes;

  @override
  Widget build(BuildContext context) {
    final severe = profile.isSevere && translatedAllergens.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severe ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5), width: severe ? 2 : 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(profile: profile, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(color: _emergencyInk, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      roleLabel,
                      style: const TextStyle(color: _emergencyMuted, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (translatedAllergens.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: severe ? _emergencyRed : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                severe
                    ? (isEn ? 'SEVERE ALLERGY · ANAPHYLAXIS RISK' : 'ALERGI BERAT · RISIKO ANAFILAKSIS')
                    : (isEn ? 'MILD INTOLERANCE' : 'INTOLERANSI RINGAN'),
                style: TextStyle(
                  color: severe ? Colors.white : const Color(0xFF78350F),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEn ? 'MUST NOT EAT / CONTAIN:' : 'TIDAK BOLEH MENGANDUNG:',
              style: const TextStyle(
                color: _emergencyMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final allergen in translatedAllergens)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block_rounded, size: 18, color: _emergencyRed),
                        const SizedBox(width: 6),
                        Text(
                          allergen,
                          style: const TextStyle(color: _emergencyDarkRed, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: severe ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: severe ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                severe
                    ? (isEn
                        ? 'STRICTLY AVOID the allergens above and any cross-contamination from shared utensils or facilities. If breathing difficulty, swelling, or dizziness occurs, seek emergency medical help immediately.'
                        : 'HINDARI sepenuhnya alergen di atas serta kontaminasi silang dari alat masak atau fasilitas produksi yang sama. Jika muncul sesak napas, bengkak, atau pusing, segera cari pertolongan medis darurat.')
                    : (isEn
                        ? 'Please avoid the ingredients listed above in any food or beverage served.'
                        : 'Mohon hindari bahan yang tercantum di atas dalam makanan atau minuman yang disajikan.'),
                style: const TextStyle(color: _emergencyInk, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.45),
              ),
            ),
          ],
          if (dietaryNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isEn ? 'Additional Dietary Preferences' : 'Catatan Diet Tambahan',
              style: const TextStyle(color: _emergencyMuted, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final note in dietaryNotes)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      note,
                      style: const TextStyle(color: Color(0xFF78350F), fontSize: 13, fontWeight: FontWeight.w700),
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

class _EmptyEmergencyCard extends StatelessWidget {
  const _EmptyEmergencyCard({
    required this.isEn,
    required this.hasAnyProfiles,
    required this.onManage,
  });

  final bool isEn;
  final bool hasAnyProfiles;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded, size: 48, color: _emergencyRed),
          const SizedBox(height: 12),
          Text(
            isEn ? 'No Active Allergy Profiles Yet' : 'Belum Ada Profil Alergi Aktif',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _emergencyInk, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Add or activate a family profile with allergens so this card is ready to show anytime offline.'
                : 'Tambahkan atau aktifkan profil keluarga beserta alergen agar kartu darurat ini siap ditunjukkan kapan saja tanpa internet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _emergencyMuted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.group_add_outlined),
              label: Text(
                hasAnyProfiles
                    ? (isEn ? 'Manage Family Profiles' : 'Atur Profil Keluarga')
                    : (isEn ? 'Add Family Profile' : 'Tambah Profil Keluarga'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _emergencyRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

