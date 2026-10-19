import 'package:flutter/material.dart';

import '../models/pemeriksaan.dart';
import '../theme.dart';

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String fmtTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
String fmtTanggalPendek(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';
String fmtJam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String fmtKadar(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

Color statusColor(String s) {
  switch (s) {
    case 'normal':
      return const Color(0xFF17803D);
    case 'waspada':
      return AppColors.orange2;
    case 'kritis':
      return const Color(0xFFC62828);
    default:
      return AppColors.muted;
  }
}

String statusLabel(String s) {
  switch (s) {
    case 'normal':
      return 'Normal';
    case 'waspada':
      return 'Warning';
    case 'kritis':
      return 'Kritis';
    default:
      return '-';
  }
}

class GradientHeader extends StatelessWidget {
  final Widget child;
  const GradientHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.teal, AppColors.teal2],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: child,
      );
}

/// Header halaman dalam: tombol kembali + judul.
class SubHeader extends StatelessWidget {
  final String title;
  final Widget? bottom;
  const SubHeader({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) => GradientHeader(
        child: Column(
          children: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 48),
            ]),
            if (bottom != null) ...[const SizedBox(height: 8), bottom!],
          ],
        ),
      );
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(statusLabel(status),
          style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class BabyAvatar extends StatelessWidget {
  final double size;
  const BabyAvatar({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFE3B8)),
        child: Icon(Icons.child_care, color: AppColors.orange2, size: size * 0.6),
      );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted)),
      );
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );
}

class ErrorBox extends StatelessWidget {
  final Object error;
  const ErrorBox(this.error, {super.key});

  // Pesan error Firestore memuat tautan pembuatan indeks, jadi dibuat bisa disalin.
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText('Gagal memuat data:\n$error',
            style: const TextStyle(color: Color(0xFFC62828), fontSize: 12)),
      );
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GradientButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(colors: [AppColors.orange1, AppColors.orange2]),
            boxShadow: const [
              BoxShadow(color: Color(0x44FF8A00), blurRadius: 18, offset: Offset(0, 8))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ),
        ),
      );
}

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class BottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
        ]),
        child: SafeArea(
          top: false,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(items[i].icon, color: i == index ? AppColors.teal : AppColors.muted),
                      const SizedBox(height: 2),
                      Text(items[i].label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w400,
                              color: i == index ? AppColors.teal : AppColors.muted)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      );
}

/// Kartu pemeriksaan: dipakai di Home (dengan nama) dan Riwayat (dengan tanggal).
class PemeriksaanTile extends StatelessWidget {
  final Pemeriksaan p;
  final String title;
  final String? subtitle;
  final bool avatar;
  final VoidCallback? onTap;
  const PemeriksaanTile({
    super.key,
    required this.p,
    required this.title,
    this.subtitle,
    this.avatar = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = statusColor(p.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x120B7A93), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(children: [
            Container(width: 6, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  if (avatar) ...[const BabyAvatar(size: 42), const SizedBox(width: 12)],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 3),
                      Row(children: [
                        if (subtitle != null)
                          Text('$subtitle  •  ',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        Text('${fmtKadar(p.hasil)} mg/dL',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
                      ]),
                    ]),
                  ),
                  if (p.pending)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.cloud_off, size: 16, color: AppColors.muted),
                    ),
                  StatusBadge(p.status),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
