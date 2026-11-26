import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_profile.dart';
import '../providers/profile_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _confirmDelete(BuildContext context, FamilyProfile profile) async {
    final provider = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus profil ${profile.name}?'),
        content: const Text('Profil ini tidak akan dipakai lagi saat memeriksa hasil pindaian.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await provider.deleteProfile(profile.id);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Profil ${profile.name} dihapus' : (provider.errorMessage ?? 'Gagal menghapus profil.')),
    ));
  }

  Future<void> _toggle(BuildContext context, FamilyProfile profile) async {
    final provider = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await provider.toggleActive(profile.id)) {
      messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Gagal mengubah profil.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profiles = provider.profiles;
    void openForm([FamilyProfile? profile]) => Navigator.pushNamed(context, AppRoutes.profileForm, arguments: profile);

    final Widget body;
    if (provider.status == ProfileStatus.loading || provider.status == ProfileStatus.initial) {
      body = const LoadingIndicator(message: 'Memuat profil keluarga...');
    } else if (provider.status == ProfileStatus.error && profiles.isEmpty) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: provider.errorMessage ?? 'Gagal memuat profil keluarga.',
        actionLabel: 'Coba Lagi',
        onAction: provider.load,
      );
    } else if (profiles.isEmpty) {
      body = EmptyState(
        icon: Icons.group_add_outlined,
        title: 'Belum ada profil keluarga',
        message: 'Tambahkan profil untuk tiap anggota keluarga agar hasil pindaian disesuaikan dengan alergi masing-masing.',
        actionLabel: 'Tambah Profil',
        onAction: openForm,
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Profil aktif dipakai saat menganalisis hasil pindaian. Matikan sakelar untuk melewati profil tertentu.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final profile in profiles) ...[
            _ProfileTile(
              profile: profile,
              busy: provider.isBusy,
              onToggle: () => _toggle(context, profile),
              onEdit: () => openForm(profile),
              onDelete: () => _confirmDelete(context, profile),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: openForm,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Tambah Profil'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: const Text('Profil Keluarga'),
        actions: [
          IconButton(
            tooltip: 'Kartu Darurat Alergi',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencyCard),
            icon: const Icon(Icons.medical_services_outlined, color: Color(0xFFB91C1C)),
          ),
        ],
      ),
      body: SafeArea(bottom: !embedded, child: body),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyProfile profile;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: profile.isActive ? const Color(0xFF6EE7B7) : scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              ProfileAvatar(profile: profile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.name} · ${profile.role}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(profile.summary, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    if (profile.allergens.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.sensitivity.label,
                        style: TextStyle(
                          color: profile.isSevere ? const Color(0xFF991B1B) : scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: profile.isActive,
                onChanged: busy ? null : (_) => onToggle(),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi profil',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

