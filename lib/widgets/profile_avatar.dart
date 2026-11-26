import 'package:flutter/material.dart';

import '../models/family_profile.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 22});

  final FamilyProfile profile;
  final double radius;

  static String? imageFor(String role) => switch (role) {
        'Anak' => 'assets/home/child.png',
        'Ayah' => 'assets/home/father.png',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final image = imageFor(profile.role);
    final initial = profile.name.trim().isEmpty ? '?' : profile.name.trim()[0].toUpperCase();
    return Semantics(
      label: 'Avatar ${profile.role}',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD1FAE5),
        backgroundImage: image == null ? null : AssetImage(image),
        child: image == null
            ? Text(
                initial,
                style: TextStyle(color: const Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: radius * .8),
              )
            : null,
      ),
    );
  }
}

