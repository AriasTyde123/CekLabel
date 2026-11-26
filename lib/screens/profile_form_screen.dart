import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_profile.dart';
import '../providers/profile_provider.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.profile});

  /// Existing profile to edit, or null to create a new one.
  final FamilyProfile? profile;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  late FamilyProfile _draft;
  late final TextEditingController _nameController;
  String? _nameError;
  String? _filterError;

  bool get _isNew => widget.profile == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.profile ?? FamilyProfile(id: context.read<ProfileProvider>().newId(), name: '');
    _nameController = TextEditingController(text: _draft.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(FamilyProfile next) => setState(() {
        _draft = next;
        if (_filterError != null) _filterError = ProfileProvider.validateFilters(next);
      });

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final draft = _draft.copyWith(name: _nameController.text);
    setState(() {
      _nameError = ProfileProvider.validateName(draft.name);
      _filterError = ProfileProvider.validateFilters(draft);
    });
    if (_nameError != null || _filterError != null) return;
    if (await provider.saveProfile(draft)) {
      messenger.showSnackBar(SnackBar(content: Text('Profil ${draft.name.trim()} tersimpan')));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan profil. Coba lagi.')));
    }
  }

  Future<void> _delete() async {
    final provider = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus profil ${_draft.name}?'),
        content: const Text('Profil ini tidak akan dipakai lagi saat memeriksa hasil pindaian.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (await provider.deleteProfile(_draft.id)) {
      messenger.showSnackBar(SnackBar(content: Text('Profil ${_draft.name} dihapus')));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Gagal menghapus profil.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<ProfileProvider>().isBusy;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(text, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Tambah Profil' : 'Ubah Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = ProfileProvider.validateName(_nameController.text));
                }
              },
              decoration: InputDecoration(
                labelText: 'Nama panggilan',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            sectionTitle('Peran dalam keluarga'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in profileRoles)
                  ChoiceChip(
                    label: Text(role),
                    selected: _draft.role == role,
                    onSelected: (_) => _update(_draft.copyWith(role: role)),
                  ),
              ],
            ),
            sectionTitle('Alergen yang dihindari'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final allergen in availableAllergens)
                  FilterChip(
                    label: Text(allergen),
                    selected: _draft.allergens.contains(allergen),
                    onSelected: (selected) {
                      final updated = {..._draft.allergens};
                      selected ? updated.add(allergen) : updated.remove(allergen);
                      _update(_draft.copyWith(allergens: updated));
                    },
                  ),
              ],
            ),
            sectionTitle('Tingkat sensitivitas'),
            SegmentedButton<SensitivityLevel>(
              segments: const [
                ButtonSegment(value: SensitivityLevel.mild, label: Text('Ringan'), icon: Icon(Icons.healing_outlined)),
                ButtonSegment(
                  value: SensitivityLevel.severe,
                  label: Text('Berat'),
                  icon: Icon(Icons.emergency_outlined),
                ),
              ],
              selected: {_draft.sensitivity},
              onSelectionChanged: (value) => _update(_draft.copyWith(sensitivity: value.first)),
            ),
            const SizedBox(height: 6),
            Text(
              _draft.isSevere
                  ? 'Alergi Berat / Anafilaksis: peringatan "dapat mengandung" langsung dianggap Bahaya.'
                  : 'Intoleransi Ringan: peringatan "dapat mengandung" dianggap Waspada.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            sectionTitle('Filter tambahan'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hindari Gula Tersembunyi'),
              subtitle: const Text('Tandai maltodekstrin, sirup glukosa, dan nama samaran gula lain.'),
              value: _draft.avoidHiddenSugar,
              onChanged: (value) => _update(_draft.copyWith(avoidHiddenSugar: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hindari MSG & Pewarna Sintetis'),
              subtitle: const Text('Tandai penguat rasa, pengawet, dan pewarna seperti tartrazin.'),
              value: _draft.avoidAdditives,
              onChanged: (value) => _update(_draft.copyWith(avoidAdditives: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Filter Bahan Syubhat / Non-Halal'),
              subtitle: const Text('Tandai babi/lard, alkohol/mirin, gelatin, karmin (E120), E471, dan lemak hewani.'),
              value: _draft.avoidSyubhat,
              onChanged: (value) => _update(_draft.copyWith(avoidSyubhat: value)),
            ),
            if (_filterError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_filterError!, style: textTheme.bodySmall?.copyWith(color: scheme.error)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: const Text('Simpan Profil'),
            ),
            if (!_isNew) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Profil'),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

