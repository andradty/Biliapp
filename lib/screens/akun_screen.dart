import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AkunScreen extends StatelessWidget {
  final AppUser user;
  const AkunScreen({super.key, required this.user});

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        GradientHeader(
          child: Column(children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: AppColors.teal),
            ),
            const SizedBox(height: 10),
            Text(user.nama,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(user.isPetugas ? 'Petugas' : 'Orang Tua',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Account Information',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 14),
            _row('Username', user.nama),
            _row('Email', user.email),
            _row('Nomor Telepon', user.nohp),
            if (user.isPetugas) _row('Puskesmas', user.puskesmasId ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => AuthService().logout(),
                child: const Text('Logout'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
