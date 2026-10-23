import 'package:flutter/material.dart';

import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/agenda_petugas.dart';
import '../widgets/common.dart';
import '../widgets/tren_chart.dart';
import 'hasil_screen.dart';

/// Dipakai Petugas (semua pasien) dan Orang Tua (anaknya) lewat stream berbeda.
class RiwayatPasienScreen extends StatelessWidget {
  final Pasien pasien;
  final Stream<List<Pemeriksaan>> stream;
  final DataService? svc; // diisi untuk Petugas (mengaktifkan tombol Batalkan)
  const RiwayatPasienScreen({super.key, required this.pasien, required this.stream, this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          SubHeader(
            title: 'Riwayat Pasien',
            bottom: Row(children: [
              const BabyAvatar(size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pasien.nama,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('${pasien.usia} • ${pasien.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Pemeriksaan>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) return SingleChildScrollView(child: ErrorBox(snap.error!));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                  const SizedBox(height: 12),
                  TrenChart(data: list.where((e) => !e.dibatalkan).toList()),
                  if (svc != null && svc!.user.isPetugas)
                    AgendaPasienSection(svc: svc!, pasien: pasien),
                  const SectionLabel('RIWAYAT PEMERIKSAAN'),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada pemeriksaan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted)),
                    ),
                  for (final e in list)
                    PemeriksaanTile(
                      p: e,
                      avatar: false,
                      title: '${fmtTanggal(e.waktu)} • ${fmtJam(e.waktu)}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HasilScreen(p: e, namaPasien: pasien.nama, svc: svc)),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}