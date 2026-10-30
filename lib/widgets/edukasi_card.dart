import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Teks edukasi per status hasil. Semua kalimat ada di satu tempat ini
/// supaya mudah direvisi tenaga kesehatan / dosen mitra tanpa menyentuh UI.
class EdukasiTeks {
  final IconData ikon;
  final String judul;
  final String penjelasan;
  final List<String> langkah;
  const EdukasiTeks(this.ikon, this.judul, this.penjelasan, this.langkah);
}

const _normal = EdukasiTeks(
  Icons.check_circle_rounded,
  'Hasil dalam batas normal',
  'Kadar kuning (bilirubin) bayi pada pemeriksaan ini masih dalam batas normal. '
      'Namun kuning bisa muncul atau naik pada hari-hari berikutnya, jadi tetap perlu dipantau.',
  [
    'Susui bayi sesering mungkin, sekitar 8–12 kali sehari untuk bayi baru lahir.',
    'Lihat warna kulit dan putih mata bayi di tempat yang terang setiap hari.',
    'Pastikan bayi sering buang air kecil dan buang air besar.',
    'Lakukan pemeriksaan ulang sesuai jadwal dari Puskesmas.',
  ],
);

const _waspada = EdukasiTeks(
  Icons.error_rounded,
  'Hasil perlu perhatian',
  'Kadar kuning bayi lebih tinggi dari yang diharapkan. Ini belum tentu berbahaya, '
      'tetapi perlu dipantau dan diperiksa lebih lanjut oleh petugas kesehatan.',
  [
    'Datang ke Puskesmas hari ini atau besok untuk pemeriksaan lanjutan.',
    'Tetap susui bayi sesering mungkin.',
    'Jangan memberi air putih, madu, atau ramuan tambahan tanpa saran petugas kesehatan.',
    'Perhatikan apakah kuning makin meluas, misalnya sampai perut, tangan, atau kaki.',
    'Pantau popok: bayi harus tetap sering buang air kecil.',
  ],
);

const _kritis = EdukasiTeks(
  Icons.warning_rounded,
  'Segera ke tenaga kesehatan',
  'Kadar kuning bayi tergolong tinggi. Bayi perlu diperiksa dan mendapat penanganan '
      'dari tenaga kesehatan secepatnya.',
  [
    'Bawa bayi ke Puskesmas atau rumah sakit hari ini juga.',
    'Jangan menunggu kuning hilang sendiri.',
    'Tetap susui bayi selama dalam perjalanan.',
    'Jangan memberi obat atau ramuan sendiri.',
  ],
);

const tandaBahaya = [
  'Bayi sangat mengantuk, lemas, atau sulit dibangunkan',
  'Bayi tidak mau menyusu atau sering muntah',
  'Demam, atau badan teraba sangat dingin',
  'Tangisan melengking, badan kaku atau melengkung, atau kejang',
  'Kuning sampai telapak tangan dan kaki',
  'Tinja pucat seperti dempul, atau air seni berwarna pekat',
];

EdukasiTeks? edukasiUntuk(String status) {
  switch (status) {
    case 'normal':
      return _normal;
    case 'waspada':
      return _waspada;
    case 'kritis':
      return _kritis;
    default:
      return null;
  }
}

/// Kartu penjelasan hasil dengan bahasa sederhana untuk orang awam.
class EdukasiCard extends StatelessWidget {
  final String status;
  const EdukasiCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = edukasiUntuk(status);
    if (t == null) return const SizedBox.shrink();
    final c = statusColor(status);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(t.ikon, color: c, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t.judul,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(t.penjelasan, style: const TextStyle(fontSize: 14.5, height: 1.45)),
          const SizedBox(height: 14),
          const Text('Yang bisa dilakukan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final s in t.langkah)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_rounded, size: 20, color: c),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 14.5, height: 1.4))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.local_hospital_rounded, color: Color(0xFFC62828), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('Segera ke fasilitas kesehatan jika bayi:',
                  style: TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFC62828))),
            ),
          ]),
          const SizedBox(height: 8),
          for (final s in tandaBahaya)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('•  ', style: TextStyle(fontSize: 14.5)),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 14, height: 1.4))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      const Text(
        'Hasil ini adalah skrining awal dan bukan diagnosis. Informasi di atas bersifat '
        'edukasi dan tidak menggantikan pemeriksaan oleh tenaga kesehatan.',
        style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
      ),
    ]);
  }
}