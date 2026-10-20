import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/bar_harian_chart.dart';
import '../../widgets/common.dart';
import '../riwayat_pasien_screen.dart';

/// Ringkasan 30 hari: sebaran status dan pasien yang hasil terakhirnya
/// belum normal (perlu tindak lanjut).
class RingkasanAdmin extends StatelessWidget {
  final List<Pemeriksaan> data; // urut waktu menurun
  final Map<String, Pasien> pasien;
  final DataService svc;
  const RingkasanAdmin({super.key, required this.data, required this.pasien, required this.svc});

  @override
  Widget build(BuildContext context) {
    int hitung(String s) => data.where((e) => e.status == s).length;

    // Hasil TERAKHIR tiap pasien; data sudah urut menurun.
    final terakhir = <String, Pemeriksaan>{};
    for (final e in data) {
      terakhir.putIfAbsent(e.pasienId, () => e);
    }
    final tindakLanjut = terakhir.values
        .where((e) => (e.status == 'waspada' || e.status == 'kritis') && pasien[e.pasienId] != null)
        .toList()
      ..sort((a, b) {
        if (a.status != b.status) return a.status == 'kritis' ? -1 : 1;
        return b.waktu.compareTo(a.waktu);
      });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Ringkasan 30 Hari'),
      Row(children: [
        _Kotak('Normal', hitung('normal'), statusColor('normal')),
        const SizedBox(width: 10),
        _Kotak('Warning', hitung('waspada'), statusColor('waspada')),
        const SizedBox(width: 10),
        _Kotak('Kritis', hitung('kritis'), statusColor('kritis')),
      ]),
      const SizedBox(height: 10),
      BarHarianChart(data: data),
      const SectionLabel('Perlu Tindak Lanjut'),
      if (tindakLanjut.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration:
              BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Text('Tidak ada pasien dengan hasil terakhir Warning atau Kritis.',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
      for (final e in tindakLanjut.take(5))
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
              subtitle: Text(
                  '${fmtTanggalPendek(e.waktu)} • ${fmtKadar(e.hasil)} ${e.satuan}',
                  style: const TextStyle(fontSize: 12)),
              trailing: StatusBadge(e.status),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiwayatPasienScreen(
                      pasien: pasien[e.pasienId]!, stream: svc.riwayatPasien(e.pasienId)),
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
  final int jumlah;
  final Color warna;
  const _Kotak(this.label, this.jumlah, this.warna);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: warna.withValues(alpha: 0.35))),
          child: Column(children: [
            Text('$jumlah',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: warna)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      );
}