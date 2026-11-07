import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'kontak_screen.dart';
import 'tentang_screen.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onStart;
  const LandingScreen({super.key, required this.onStart});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _menuOpen = false;

  void _buka(Widget page) {
    setState(() => _menuOpen = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _burgerBar() => Container(
        width: 22,
        height: 2.6,
        decoration: BoxDecoration(
          color: const Color(0xFF10233F),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _dropdownLink(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF10233F),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(
          children: [
            // Header Biru Muda persis Image 1 & Image 2
            ClipRRect(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: topPadding > 0 ? topPadding : 10,
                  bottom: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFBCE4F7),
                  border: Border(bottom: BorderSide(color: Color(0xFF9BB8C9), width: 1)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran hijau menempel di pojok kanan paling ujung (Image 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 58,
                        decoration: const BoxDecoration(
                          color: Color(0xFF88B39B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(29),
                            bottomLeft: Radius.circular(29),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 6,
                      bottom: 6,
                      child: Container(
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B9C82).withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            bottomLeft: Radius.circular(22),
                          ),
                        ),
                      ),
                    ),

                    // Konten header: logo di kiri, burger di kanan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/logo-bilicheck-one.png',
                            height: 44,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.water_drop_rounded,
                              size: 38,
                              color: AppColors.orange2,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _menuOpen = !_menuOpen),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _burgerBar(),
                                  const SizedBox(height: 4.5),
                                  _burgerBar(),
                                  const SizedBox(height: 4.5),
                                  _burgerBar(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Konten landing + dropdown burger (Image 1 & 2)
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Bagian atas berlatar gradien Figma
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                            child: Column(
                              children: [
                                // Logo BiliCheck di atas judul (sesuai desain asli Image 3)
                                Center(
                                  child: Image.asset(
                                    'assets/logo-bilicheck.png',
                                    width: 240,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'Skrining bilirubin baby, lebih cepat dan terpaut',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'Atbat pembaca kadar bilirubin berlaku ITS untuk Puskesmas dan Posyandu, '
                                    'dengan aplikasi untuk Petugas dan Orang Tua.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF637385),
                                      height: 1.5,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: _GradientButton(
                                      label: 'Masuk / Daftar', onPressed: widget.onStart),
                                ),

                                const _Heading('APA ITU BILIRUBIN?'),
                                const _InfoCard(
                                  emoji: '🩸',
                                  title: 'Pigmen kuning dalam darah',
                                  body:
                                      'Bilirubin terbentuk saat sel darah merah rusak dan diolah oleh hati.',
                                ),
                                const _InfoCard(
                                  emoji: '👶',
                                  title: 'Bayi kuning (jaundice)',
                                  body:
                                      'Pigmen bilirubin membuat kulit dan mata bayi terlihat kuning.',
                                ),
                                const _InfoCard(
                                  emoji: '⚠️',
                                  title: 'Bahaya kadar tinggi',
                                  body:
                                      'Terlalu tinggi dapat menyebabkan gangguan saraf jika tidak ditangani.',
                                ),

                                const _Heading('Tentang alat BiliCheck'),
                                const _InfoCard(
                                  icon: Icons.sensors,
                                  title: 'Sensor optik fotodioda',
                                  body:
                                      'Alat membaca sampel yang diserahkan petugas menggunakan sensor '
                                      'fotodioda. Sinyal sensor diproses mikrokontroler ESP32.',
                                ),
                                const _InfoCard(
                                  icon: Icons.tune,
                                  title: 'Terkalibrasi',
                                  body:
                                      'Kadar bilirubin dihitung dari sinyal sensor memakai koefisien '
                                      'kalibrasi perangkat, sehingga hasil mengacu pada kalibrasi terbaru.',
                                ),
                                const _InfoCard(
                                  icon: Icons.cloud_outlined,
                                  title: 'Terhubung ke cloud',
                                  body:
                                      'Hasil dikirim lewat WiFi ke Firebase dan langsung muncul di '
                                      'aplikasi. Aplikasi dan alat tidak berkomunikasi langsung.',
                                ),

                                const _Heading('Cara kerja'),
                                const _Step(
                                    n: 1,
                                    text: 'Petugas memilih pasien dan menekan Mulai Pemeriksaan.'),
                                const _Step(
                                    n: 2,
                                    text: 'Sampel dimasukkan, sensor membaca dan menghitung kadar.'),
                                const _Step(
                                    n: 3, text: 'Hasil dikirim ke cloud dan tampil di aplikasi.'),
                                const _Step(
                                    n: 4,
                                    text: 'Orang Tua menerima notifikasi dan dapat melihat riwayat.'),

                                const _Heading('Aplikasi untuk siapa?'),
                                const _InfoCard(
                                  icon: Icons.medical_services_outlined,
                                  title: 'Petugas Puskesmas',
                                  body:
                                      'Mendaftarkan pasien, menjalankan pemeriksaan, mencatat kalibrasi, '
                                      'dan melihat riwayat semua pasien di Puskesmasnya.',
                                ),
                                const _InfoCard(
                                  icon: Icons.family_restroom,
                                  title: 'Orang Tua',
                                  body:
                                      'Melihat hasil dan riwayat pemeriksaan anak serta menerima '
                                      'notifikasi saat hasil tersedia.',
                                ),

                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFDCE4EC)),
                                  ),
                                  child: const Text(
                                    'BiliCheck adalah alat bantu skrining, bukan pengganti diagnosis dokter. '
                                    'Hasil yang mengkhawatirkan perlu dikonfirmasi tenaga kesehatan.',
                                    style: TextStyle(
                                        fontSize: 12.5, color: AppColors.muted, height: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),

                          // Section Footer Full-Width Berbatas Tegas (ala Clove / Squarespace)
                          _FooterSection(
                            onBukaTentang: () => _buka(const TentangScreen()),
                            onBukaKontak: () => _buka(const KontakScreen()),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dropdown Burger (Image 2)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    top: _menuOpen ? 0 : -220,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _menuOpen ? 1.0 : 0.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFCAEAF9),
                          border: Border(bottom: BorderSide(color: Color(0xFF6C7A89), width: 1)),
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dropdownLink('Home', () => setState(() => _menuOpen = false)),
                            _dropdownLink('About Us', () => _buka(const TentangScreen())),
                            _dropdownLink('Our Team', () => _buka(const KontakScreen())),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A6D88),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _menuOpen = false);
                                  widget.onStart();
                                },
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                      fontSize: 12.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF146C82),
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String title;
  final String body;
  const _InfoCard({this.icon, this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3ECF2)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A10233F), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F2F6),
            borderRadius: BorderRadius.circular(15),
          ),
          child: emoji != null
              ? Text(emoji!, style: const TextStyle(fontSize: 25))
              : Icon(icon, color: AppColors.teal, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(body,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7B8E),
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.teal,
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ]),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFAF36), Color(0xFFFF9800)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Footer landing page ala referensi Clove/Squarespace:
/// Full-width membentang ke pinggir layar dengan batas garis atas yang jelas,
/// memuat Alamat, Kontak, Informasi, dan Instagram dari Hubungi Kami.
class _FooterSection extends StatelessWidget {
  final VoidCallback onBukaTentang;
  final VoidCallback onBukaKontak;

  const _FooterSection({
    required this.onBukaTentang,
    required this.onBukaKontak,
  });

  void _salin(BuildContext context, String label, String text) async {
    final m = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    m.showSnackBar(SnackBar(content: Text('$label disalin')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFD6E2EC), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Header Footer: Logo & Identitas
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo-bilicheck-one.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.water_drop_rounded,
                  size: 34,
                  color: AppColors.orange2,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'BiliCheck',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Inovasi Skrining Kadar Bilirubin Bayi',
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alamat dari kontak_screen.dart
          const Text(
            kAlamatTim,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          // Dua Kolom: Kontak Kami & Informasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom 1: Kontak Kami (Email & WA)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kontak Kami',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _salin(context, 'Email', kEmailTim),
                      child: Row(
                        children: const [
                          Icon(Icons.email_outlined, size: 15, color: AppColors.teal),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              kEmailTim,
                              style: TextStyle(fontSize: 12, color: Color(0xFF556575)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _salin(context, 'WhatsApp', kWhatsAppTim),
                      child: Row(
                        children: const [
                          Icon(Icons.chat_outlined, size: 15, color: AppColors.teal),
                          SizedBox(width: 6),
                          Text(
                            kWhatsAppTim,
                            style: TextStyle(fontSize: 12, color: Color(0xFF556575)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Kolom 2: Informasi (Tentang Tim & Hubungi Kami)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: onBukaTentang,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          'Tentang Tim',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF556575), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onBukaKontak,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          'Hubungi Kami',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF556575), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Baris Bawah: Ikuti Kami (Instagram) & Copyright
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text(
                    'Ikuti kami: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  InkWell(
                    onTap: () => _salin(context, 'Instagram', kInstagramTim),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10233F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            kInstagramTim,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                '© 2026 BiliCheck',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
