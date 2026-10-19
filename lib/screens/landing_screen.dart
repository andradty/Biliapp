import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onStart;
  const LandingScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  SvgPicture.asset('assets/logo.svg', height: 90),
                  const SizedBox(height: 28),
                  const Text(
                    'Skrining bilirubin bayi, lebih cepat dan terpantau',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alat pembaca kadar bilirubin berbasis IoT untuk Puskesmas dan Posyandu, '
                    'dengan aplikasi untuk Petugas dan Orang Tua.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  _GradientButton(label: 'Masuk / Daftar', onPressed: onStart),

                  const _Heading('Apa itu bilirubin?'),
                  const _InfoCard(
                    icon: Icons.water_drop,
                    title: 'Pigmen kuning dalam darah',
                    body: 'Bilirubin terbentuk saat sel darah merah tua dipecah tubuh, lalu '
                        'diolah oleh hati dan dibuang lewat tinja. Pada bayi baru lahir, hati '
                        'belum bekerja optimal sehingga bilirubin mudah menumpuk.',
                  ),
                  const _InfoCard(
                    icon: Icons.child_care,
                    title: 'Bayi kuning (jaundice)',
                    body: 'Penumpukan bilirubin membuat kulit dan bagian putih mata tampak '
                        'kuning. Sebagian besar ringan dan hilang sendiri, tetapi kadar yang '
                        'terlalu tinggi dapat membahayakan, termasuk gangguan pada otak '
                        '(kernikterus).',
                  ),
                  const _InfoCard(
                    icon: Icons.timer_outlined,
                    title: 'Mengapa deteksi dini penting',
                    body: 'Pemeriksaan umumnya lewat sampel darah, yang menyakitkan bagi bayi '
                        'dan hasilnya kadang lambat di Puskesmas. Deteksi dini membantu '
                        'tenaga kesehatan mengambil keputusan lebih cepat.',
                  ),

                  const _Heading('Tentang alat BiliCheck'),
                  const _InfoCard(
                    icon: Icons.sensors,
                    title: 'Sensor optik fotodioda',
                    body: 'Alat membaca sampel yang diserahkan petugas menggunakan sensor '
                        'fotodioda. Sinyal sensor diproses mikrokontroler ESP32.',
                  ),
                  const _InfoCard(
                    icon: Icons.tune,
                    title: 'Terkalibrasi',
                    body: 'Kadar bilirubin dihitung dari sinyal sensor memakai koefisien '
                        'kalibrasi perangkat, sehingga hasil mengacu pada kalibrasi terbaru.',
                  ),
                  const _InfoCard(
                    icon: Icons.cloud_outlined,
                    title: 'Terhubung ke cloud',
                    body: 'Hasil dikirim lewat WiFi ke Firebase dan langsung muncul di '
                        'aplikasi. Aplikasi dan alat tidak berkomunikasi langsung.',
                  ),

                  const _Heading('Cara kerja'),
                  const _Step(n: 1, text: 'Petugas memilih pasien dan menekan Mulai Pemeriksaan.'),
                  const _Step(n: 2, text: 'Sampel dimasukkan, sensor membaca dan menghitung kadar.'),
                  const _Step(n: 3, text: 'Hasil dikirim ke cloud dan tampil di aplikasi.'),
                  const _Step(n: 4, text: 'Orang Tua menerima notifikasi dan dapat melihat riwayat.'),

                  const _Heading('Aplikasi untuk siapa?'),
                  const _InfoCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Petugas Puskesmas',
                    body: 'Mendaftarkan pasien, menjalankan pemeriksaan, mencatat kalibrasi, '
                        'dan melihat riwayat semua pasien di Puskesmasnya.',
                  ),
                  const _InfoCard(
                    icon: Icons.family_restroom,
                    title: 'Orang Tua',
                    body: 'Melihat hasil dan riwayat pemeriksaan anak serta menerima '
                        'notifikasi saat hasil tersedia.',
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'BiliCheck adalah alat bantu skrining, bukan pengganti diagnosis dokter. '
                      'Hasil yang mengkhawatirkan perlu dikonfirmasi tenaga kesehatan.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GradientButton(label: 'Masuk / Daftar', onPressed: onStart),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2026 BiliCheck · Kelompok 9',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
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
        padding: const EdgeInsets.only(top: 34, bottom: 14),
        child: Text(text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.teal)),
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x140B7A93), blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(colors: [AppColors.teal2, AppColors.teal]),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.orange1, AppColors.orange2]),
              ),
              child: Text('$n',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
          ],
        ),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
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
      );
}
