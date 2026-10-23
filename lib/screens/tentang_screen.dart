import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Ubah daftar ini kalau ada perubahan anggota/peran.
const String kNamaKelompok = 'Kelompok 9';
const String kInstitusi = 'Sekolah Vokasi IPB University';
const String kMitra = 'Aep Setiawan, S.Si., M.Si.';

/// nama -> peran (kosongkan peran kalau belum ingin ditampilkan)
const Map<String, String> kAnggotaTim = {
  'Nala Arham Rozana': 'Manajer Proyek • Aplikasi Mobile',
  'Raditya Rakha Irianto': 'Anggota Tim',
  'Faiz Aidil Baihaqi': 'Anggota Tim',
  'Ammar Hudzafah': 'Anggota Tim',
  'Muhammad Adam Ilyasa': 'Anggota Tim',
  "Daffa' Raihandi": 'Anggota Tim',
  'Ramaditya Devara Mulya': 'Anggota Tim',
  'Deandra Aidila Hidayat': 'Anggota Tim',
};

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  Widget _kartu(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Tentang Kami'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const SectionLabel('Tentang BiliCheck'),
              _kartu(const Text(
                'BiliCheck adalah alat pembaca kadar bilirubin non-invasif berbasis IoT untuk '
                'membantu skrining bayi kuning (jaundice) di Puskesmas dan Posyandu. Hasil '
                'pembacaan dikirim ke cloud dan dapat dipantau lewat aplikasi ini.',
                style: TextStyle(height: 1.55, color: AppColors.muted),
              )),
              const SectionLabel('Mitra Proyek'),
              _kartu(Row(children: [
                const Icon(Icons.handshake_outlined, color: AppColors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text(kMitra, style: TextStyle(fontWeight: FontWeight.w600)),
                    const Text('Dosen mitra',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
              ])),
              SectionLabel('Tim $kNamaKelompok'),
              _kartu(Text('$kInstitusi',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted))),
              for (final e in kAnggotaTim.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.teal,
                      child: Text(e.key.characters.first.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (e.value.isNotEmpty)
                          Text(e.value,
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
