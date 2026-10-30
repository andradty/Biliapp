import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'akun_sheets.dart';

class AkunScreen extends StatelessWidget {
  final AppUser user;
  const AkunScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        // Header berlatar gradien teal dengan dekorasi lingkaran hijau (persis Image 5 & Image 6)
        GradientHeader(
          showLeftCircle: true,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 22),
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 36,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF072B3A), width: 4),
              ),
              child: const Icon(Icons.person, size: 54, color: Color(0xFF072B3A)),
            ),
            const SizedBox(height: 12),
            Text(
              user.nama,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 22, 24, 32), children: [
            const Text(
              'Account Information',
              style: TextStyle(
                color: Color(0xFF7B8794),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _RowEdit(
              label: 'Username',
              value: user.nama,
              onTap: () => bukaUbahProfil(context, user),
            ),
            _RowEdit(
              label: 'Email',
              value: user.email,
              onTap: () => bukaUbahProfil(context, user),
            ),
            _RowEdit(
              label: 'Nomor Telepon',
              value: user.nohp.isEmpty ? '-' : user.nohp,
              onTap: () => bukaUbahProfil(context, user),
            ),
            if (user.isPetugas && (user.puskesmasId ?? '').isNotEmpty)
              _RowEdit(
                label: 'Puskesmas',
                value: user.puskesmasId!,
                onTap: () => bukaUbahProfil(context, user),
              ),
            const SizedBox(height: 18),
            const Text(
              'Password & Security',
              style: TextStyle(
                color: Color(0xFF7B8794),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _RowEdit(
              label: 'Password',
              value: '****************',
              onTap: () => bukaGantiPassword(context),
            ),
            const SizedBox(height: 8),
            _SecurityLink(
              title: 'Multi-Factor Authentication',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Multi-Factor Authentication sudah aktif melalui Firebase Auth.')),
                );
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEE312F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: () => AuthService().logout(),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _RowEdit extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _RowEdit({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0D748E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_square, size: 20, color: Color(0xFF1E1E1E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SecurityLink({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0D748E),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 24, color: Color(0xFF1E1E1E)),
          ],
        ),
      ),
    );
  }
}
