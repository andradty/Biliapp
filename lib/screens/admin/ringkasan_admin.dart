import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/bar_harian_chart.dart';
import '../../widgets/common.dart';
import '../riwayat_pasien_screen.dart';

/// Ringkasan 30 hari: jumlah pemeriksaan, jumlah pasien, rata-rata hasil (%),
/// dan hasil terakhir beberapa pasien. Tanpa kategori status.
class RingkasanAdmin extends StatelessWidget {
  final List<Pemeriksaan> data; // urut waktu menurun
  final List<Pemeriksaan> dataGrafik; // rentang lebih panjang untuk grafik
  final Map<String, Pasien> pasien;
  final DataService svc;
  const RingkasanAdmin(
      {super.key,
      required this.data,
      required this.dataGrafik,
      required this.pasien,
      required this.svc});

  @override
  Widget build(BuildContext context) {
    final sah = data.where((e) => !e.dibatalkan).toList();

    // Hasil TERAKHIR tiap pasien; data sudah urut menurun.
    final terakhir = <String, Pemeriksaan>{};
    for (final e in sah) {
      terakhir.putIfAbsent(e.pasienId, () => e);
    }
    final rata = sah.isEmpty ? null : sah.map((e) => e.hasil).reduce((a, b) => a + b) / sah.length;
    final terbaru = terakhir.values.where((e) => pasien[e.pasienId] != null).take(5).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Ringkasan 30 Hari'),
      Row(children: [
        _Kotak('Pemeriksaan', '${sah.length}'),
        const SizedBox(width: 10),
        _Kotak('Pasien', '${terakhir.length}'),
        const SizedBox(width: 10),
        _Kotak('Rata-rata %', rata == null ? '-' : fmtKadar(rata)),
      ]),
      const SizedBox(height: 10),
      BarHarianChart(data: dataGrafik),
      const SectionLabel('Hasil Terakhir Pasien'),
      if (terbaru.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration:
              BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Text('Belum ada pemeriksaan dalam 30 hari terakhir.',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
      for (final e in terbaru)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration:
              BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: const BabyAvatar(size: 38),
              title: Text(pasien[e.pasienId]!.nama,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(fmtTanggalPendek(e.waktu), style: const TextStyle(fontSize: 12)),
              trailing: Text('${fmtKadar(e.hasil)} ${e.satuan}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.teal)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiwayatPasienScreen(
                      pasien: pasien[e.pasienId]!,
                      stream: svc.riwayatPasien(e.pasienId),
                      svc: svc),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _Kotak extends StatelessWidget {
  final String label;
  final String nilai;
  const _Kotak(this.label, this.nilai);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3))),
          child: Column(children: [
            Text(nilai,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.teal)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      );
}
