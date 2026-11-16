import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'akun_sheets.dart';

class AkunScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onBack;

  /// Hanya dipakai Petugas: membuka layar Ekspor CSV.
  final VoidCallback? onEksporData;

  const AkunScreen({super.key, required this.user, this.onBack, this.onEksporData});

  Widget _tombolKembali(BuildContext context) => Container(
        width: 36,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      );

  Widget _avatar(double ukuran, double border) => Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF072B3A), width: border),
        ),
        child: Icon(Icons.person, size: ukuran * 0.71, color: const Color(0xFF072B3A)),
      );

  Widget _nama({int? maxLines}) => Text(
        user.nama,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19.5,
          fontWeight: FontWeight.w800,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        // Header berlatar gradien teal dengan dekorasi lingkaran hijau (persis Image 5 & Image 6)
        GradientHeader(
          showLeftCircle: true,
          child: MediaQuery.orientationOf(context) == Orientation.landscape
              // Landscape: satu baris ringkas supaya tinggi header konsisten.
              ? Row(children: [
                  _tombolKembali(context),
                  const SizedBox(width: 14),
                  _avatar(44, 3),
                  const SizedBox(width: 12),
                  Expanded(child: _nama(maxLines: 1)),
                ])
              : Column(children: [
                  Align(alignment: Alignment.centerLeft, child: _tombolKembali(context)),
                  const SizedBox(height: 2),
                  _avatar(76, 4),
                  const SizedBox(height: 12),
                  _nama(),
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
            // Edit Username / Nama saja
            _RowEdit(
              label: 'Username',
              value: user.nama,
              onTap: () => bukaUbahNama(context, user),
            ),
            // Email: hanya ditampilkan, ikon edit dihilangkan
            _RowEdit(
              label: 'Email',
              value: user.email,
              bisaEdit: false,
            ),
            // Edit Nomor Telepon saja
            _RowEdit(
              label: 'Nomor Telepon',
              value: user.nohp.isEmpty ? '-' : user.nohp,
              onTap: () => bukaUbahTelepon(context, user),
            ),
            if (user.isPetugas && (user.puskesmasId ?? '').isNotEmpty)
              _RowEdit(
                label: 'Puskesmas',
                value: user.puskesmasId!,
                bisaEdit: false,
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
            if (user.isPetugas && onEksporData != null) ...[
              const SizedBox(height: 18),
              const Text(
                'Data',
                style: TextStyle(
                  color: Color(0xFF7B8794),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF0D748E)),
                title: const Text('Ekspor data (CSV)',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0D748E))),
                subtitle: const Text('Mingguan, bulanan, atau rentang custom'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onEksporData,
              ),
            ],
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
  final VoidCallback? onTap;
  final bool bisaEdit;

  const _RowEdit({
    required this.label,
    required this.value,
    this.onTap,
    this.bisaEdit = true,
  });

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
          if (bisaEdit && onTap != null)
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
