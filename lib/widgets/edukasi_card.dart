import 'package:flutter/material.dart';

import '../theme.dart';

/// Edukasi UMUM tentang bilirubin untuk orang awam. Tidak bergantung pada nilai
/// hasil. Semua kalimat ada di file ini agar mudah direvisi tenaga kesehatan /
/// dosen mitra tanpa menyentuh UI.
const _apaItu =
    'Bilirubin adalah zat berwarna kuning yang terbentuk ketika sel darah merah yang '
    'sudah tua dipecah oleh tubuh. Hati mengolah bilirubin, lalu dibuang lewat tinja '
    'dan air seni. Jika bilirubin menumpuk di tubuh, kulit dan putih mata tampak kuning. '
    'Kondisi ini disebut jaundice atau bayi kuning.';

const _mengapaBayi =
    'Hati bayi baru lahir belum bekerja sempurna, sehingga bilirubin lebih mudah menumpuk. '
    'Kuning ringan cukup sering terjadi dan umumnya membaik dalam 1 sampai 2 minggu. '
    'Namun kadar bilirubin yang terlalu tinggi dapat berbahaya bagi bayi, karena itu bayi '
    'tetap perlu dipantau oleh tenaga kesehatan.';

const _tentangAngka =
    'Angka persen pada aplikasi adalah hasil pembacaan sensor alat BiliCheck sebagai '
    'skrining awal. Angka ini bukan hasil laboratorium dalam mg/dL, dan aplikasi tidak '
    'mengelompokkannya ke kategori tertentu. Penilaian dan tindak lanjut ditentukan oleh '
    'tenaga kesehatan.';

const _dirumah = [
  'Susui bayi sesering mungkin, sekitar 8 sampai 12 kali sehari untuk bayi baru lahir.',
  'Lihat warna kulit dan putih mata bayi di tempat yang terang setiap hari.',
  'Pastikan bayi sering buang air kecil dan buang air besar.',
  'Ikuti jadwal pemeriksaan ulang dari Puskesmas.',
  'Jangan memberi air putih, madu, atau ramuan tambahan tanpa saran tenaga kesehatan.',
];

const _tandaBahaya = [
  'Kuning muncul pada 24 jam pertama setelah lahir',
  'Kuning makin meluas sampai telapak tangan dan kaki',
  'Kuning belum hilang setelah 2 minggu',
  'Bayi sangat mengantuk, lemas, atau sulit dibangunkan',
  'Bayi tidak mau menyusu atau sering muntah',
  'Demam, atau badan teraba sangat dingin',
  'Tangisan melengking, badan kaku atau melengkung, atau kejang',
  'Tinja pucat seperti dempul, atau air seni berwarna pekat',
];

/// Kartu edukasi umum tentang bilirubin dengan bahasa sederhana.
class EdukasiCard extends StatelessWidget {
  const EdukasiCard({super.key});

  Widget _kartu({required IconData ikon, required String judul, required Widget isi}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ikon, color: AppColors.teal, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(judul,
                  style: const TextStyle(
                      fontSize: 16.5, fontWeight: FontWeight.w700, color: AppColors.teal)),
            ),
          ]),
          const SizedBox(height: 10),
          isi,
        ]),
      );

  Widget _paragraf(String t) => Text(t, style: const TextStyle(fontSize: 14.5, height: 1.45));

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _kartu(
          ikon: Icons.science_outlined,
          judul: 'Apa itu bilirubin?',
          isi: _paragraf(_apaItu)),
      _kartu(
          ikon: Icons.child_care_rounded,
          judul: 'Mengapa bayi sering tampak kuning?',
          isi: _paragraf(_mengapaBayi)),
      _kartu(
          ikon: Icons.info_outline_rounded,
          judul: 'Tentang angka pada aplikasi',
          isi: _paragraf(_tentangAngka)),
      _kartu(
        ikon: Icons.favorite_border_rounded,
        judul: 'Yang bisa dilakukan di rumah',
        isi: Column(children: [
          for (final s in _dirumah)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_rounded, size: 20, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 14.5, height: 1.4))),
              ]),
            ),
        ]),
      ),
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
          for (final s in _tandaBahaya)
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
        'Informasi ini bersifat edukasi umum dan tidak menggantikan pemeriksaan atau '
        'saran dari tenaga kesehatan.',
        style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
      ),
    ]);
  }
}
