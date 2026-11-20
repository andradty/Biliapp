import 'package:flutter/material.dart';

import '../models/pemeriksaan.dart';
import '../theme.dart';

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String fmtTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
String fmtTanggalPendek(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';
String fmtJam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String fmtKadar(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Konsentrasi (C) bernilai sangat kecil (~1e-6): tampil notasi ilmiah, mis. `8,32×10⁻⁶`.
String fmtKonsentrasi(num v) {
  if (v == 0) return '0';
  final e = v.toStringAsExponential(2).split('e'); // '8.32','-6'
  const sup = {'-': '⁻', '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'};
  final pangkat = int.parse(e[1]).toString().split('').map((c) => sup[c] ?? c).join();
  return '${e[0].replaceAll('.', ',')}×10$pangkat';
}


/// Header berlatar gradien teal dengan dekorasi lingkaran hijau elegan (sesuai Image 7 & 8)
class GradientHeader extends StatelessWidget {
  final Widget child;
  final bool showLeftCircle;
  final double bottomRadius;
  final EdgeInsetsGeometry? padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.showLeftCircle = false,
    this.bottomRadius = 28,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top;
    // Landscape: padding dibuat ringkas & seragam supaya header tidak
    // berubah-ubah ukurannya dan tidak menutupi layar.
    final landscape = mq.orientation == Orientation.landscape;
    final EdgeInsetsGeometry isiPadding = padding ??
        (landscape
            ? EdgeInsets.fromLTRB(20 + mq.padding.left, topPadding + 8, 20 + mq.padding.right, 12)
            : EdgeInsets.fromLTRB(20, topPadding + 12, 20, 22));
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF075F78), Color(0xFF0E85A5)],
          ),
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif hijau di kanan atas (persis Image 7 & Image 8)
            Positioned(
              right: -32,
              top: -36,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6E9E82).withValues(alpha: 0.55),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 2,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF86B396).withValues(alpha: 0.42),
                ),
              ),
            ),
            if (showLeftCircle) ...[
              Positioned(
                left: -30,
                bottom: -32,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6E9E82).withValues(alpha: 0.48),
                  ),
                ),
              ),
              Positioned(
                left: -10,
                bottom: -16,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF86B396).withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
            Padding(
              padding: isiPadding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Header halaman dalam: tombol kembali + judul (sesuai Image 8)
class SubHeader extends StatelessWidget {
  final String title;
  final Widget? bottom;
  const SubHeader({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) => GradientHeader(
        child: Column(
          children: [
            Row(children: [
              Container(
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
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ]),
            if (bottom != null) ...[const SizedBox(height: 12), bottom!],
          ],
        ),
      );
}

class BadgeDibatalkan extends StatelessWidget {
  const BadgeDibatalkan({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Dibatalkan',
          style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
}

class BabyAvatar extends StatelessWidget {
  final double size;
  const BabyAvatar({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEBF4EC), Color(0xFFF6EBD8)],
          ),
        ),
        child: Icon(Icons.child_care_rounded, color: AppColors.orange2, size: size * 0.65),
      );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: Color(0xFF758290),
            letterSpacing: 0.3,
          ),
        ),
      );
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCE4EC)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF9AA5B1), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      );
}

class ErrorBox extends StatelessWidget {
  final Object error;
  const ErrorBox(this.error, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
        child: Text('Terjadi kesalahan: $error',
            style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
      );
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  const GradientButton({super.key, required this.label, required this.onPressed, this.width});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width ?? double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.orange1, AppColors.orange2],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x33FF8A00), blurRadius: 16, offset: Offset(0, 6))
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
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(items[i].icon,
                            size: 28,
                            color: i == index ? AppColors.teal : const Color(0xFF757575)),
                        const SizedBox(height: 2),
                        Text(items[i].label,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                                color: i == index ? AppColors.teal : const Color(0xFF757575))),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
}

/// Kartu pemeriksaan. Warna status hanya diberikan ke teks hasil (tanpa strip samping).
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
    final c = p.dibatalkan ? AppColors.muted : AppColors.teal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                        child: Row(
                          children: [
                            if (avatar) ...[
                              const BabyAvatar(size: 52),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (subtitle != null) ...[
                                        Text(
                                          '$subtitle  • ',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF7B8AA0),
                                          ),
                                        ),
                                      ],
                                      Text(
                                        '${fmtKadar(p.hasil)} ${p.satuan}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: c,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (p.dibatalkan) ...[
                                    const SizedBox(height: 5),
                                    const BadgeDibatalkan(),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFFB0BEC5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Navigasi halaman ringkas: ‹ 1 / 4 ›. Tersembunyi kalau hanya 1 halaman.
/// [halaman] dimulai dari 0.
class PaginasiBar extends StatelessWidget {
  final int halaman;
  final int total;
  final ValueChanged<int> onUbah;
  const PaginasiBar({super.key, required this.halaman, required this.total, required this.onUbah});

  Widget _panah(IconData ikon, VoidCallback? onTap) => InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(ikon,
              size: 20, color: onTap == null ? const Color(0xFFB0BEC5) : AppColors.teal),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _panah(Icons.chevron_left, halaman > 0 ? () => onUbah(halaman - 1) : null),
        const SizedBox(width: 8),
        Text('${halaman + 1} / $total',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
        const SizedBox(width: 8),
        _panah(Icons.chevron_right, halaman < total - 1 ? () => onUbah(halaman + 1) : null),
      ]),
    );
  }
}
