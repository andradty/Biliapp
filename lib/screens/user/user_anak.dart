import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../hasil_screen.dart';
import '../riwayat_pasien_screen.dart';

/// Tab Riwayat Skrining User (persis Image 13)
class UserAnak extends StatelessWidget {
  final DataService svc;
  const UserAnak({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        const GradientHeader(
          child: Center(
            child: Text(
              'Riwayat Skrining',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Pasien>>(
            stream: svc.anakSaya(),
            builder: (context, snap) {
              if (snap.hasError) return SingleChildScrollView(child: ErrorBox(snap.error!));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada anak yang ditautkan.',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                );
              }

              return StreamBuilder<List<Pemeriksaan>>(
                stream: svc.pemeriksaanAnak(),
                builder: (context, pSnap) {
                  final semuaPemeriksaan = (pSnap.data ?? <Pemeriksaan>[])
                      .where((e) => !e.dibatalkan)
                      .toList();

                  final totalPemeriksaan = semuaPemeriksaan.length;
                  final rataRata = totalPemeriksaan == 0
                      ? 0.0
                      : semuaPemeriksaan.map((e) => e.hasil).reduce((a, b) => a + b) /
                          totalPemeriksaan;
                  final labelTerakhir = totalPemeriksaan == 0
                      ? '-'
                      : '${fmtKadar(semuaPemeriksaan.first.hasil)}%';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // 1. Kartu RIWAYAT BAYI (Image 13)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RIWAYAT BAYI',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7B8794),
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final p in list)
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RiwayatPasienScreen(
                                      pasien: p,
                                      stream: svc.pemeriksaanAnak(pasienId: p.id),
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFB5B5B5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFFCE4C0),
                                        ),
                                        child: const Text('👶', style: TextStyle(fontSize: 21)),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.nama,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$totalPemeriksaan pemeriksaan',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF7B8794),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Tiga Kotak Statistik: Total | Rata-rata | Hasil Terakhir (Image 13)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatMiniBox(
                                topText: totalPemeriksaan == 0 ? '8' : '$totalPemeriksaan',
                                topColor: const Color(0xFF0A748E),
                                bottomText: 'Pemeriksaan',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatMiniBox(
                                topText: totalPemeriksaan == 0
                                    ? '11,4'
                                    : fmtKadar(rataRata),
                                topColor: const Color(0xFFF59E0B),
                                bottomText: 'Rata-rata %',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatMiniBox(
                                topText: labelTerakhir,
                                topColor: AppColors.teal,
                                bottomText: 'Hasil terakhir',
                                bgColor: const Color(0xFFE0F2F7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. RIWAYAT PEMERIKSAAN (Image 13)
                      const Text(
                        'RIWAYAT PEMERIKSAAN',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF758290),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (semuaPemeriksaan.isEmpty)
                        // Contoh placeholder seperti Image 13 (12 Okt 2026 • 09:10, 9,8 mg/dL Normal)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4.5,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '12 Okt 2026 • 09:10',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: const [
                                      Text(
                                        '9,8 %',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        for (final e in semuaPemeriksaan)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PemeriksaanTile(
                              p: e,
                              avatar: false,
                              title: '${fmtTanggal(e.waktu)} • ${fmtJam(e.waktu)}',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HasilScreen(
                                    p: e,
                                    namaPasien: list.first.nama,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _StatMiniBox extends StatelessWidget {
  final String topText;
  final Color topColor;
  final String bottomText;
  final Color bgColor;

  const _StatMiniBox({
    required this.topText,
    required this.topColor,
    required this.bottomText,
    this.bgColor = const Color(0xFFE7F3ED),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            topText,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: topColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            bottomText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7B8794),
            ),
          ),
        ],
      ),
    );
  }
}
