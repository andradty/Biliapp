import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/kalibrasi.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'kalibrasi_screen.dart';

/// Batas umur kalibrasi sebelum diberi peringatan. NILAI SEMENTARA:
/// sesuaikan dengan kebijakan kalibrasi dari tim hardware/dosen mitra.
const kBatasHariKalibrasi = 30;

/// Info alat milik Puskesmas Petugas dan kalibrasi yang sedang aktif.
class KartuInfoAlat extends StatefulWidget {
  final DataService svc;
  const KartuInfoAlat({super.key, required this.svc});

  @override
  State<KartuInfoAlat> createState() => _KartuInfoAlatState();
}

class _KartuInfoAlatState extends State<KartuInfoAlat> {
  late final Stream<DeviceInfo?> _dev = widget.svc.deviceSaya();

  static String _n(double v) => v.toString();

  Widget _baris(String label, Widget nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
          Expanded(child: nilai),
        ]),
      );

  Widget _teks(String t) =>
      Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));

  Widget _kartu(List<Widget> anak) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: anak),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceInfo?>(
      stream: _dev,
      builder: (context, snap) {
        if (snap.hasError) return ErrorBox(snap.error!);
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _kartu(const [Center(child: CircularProgressIndicator())]);
        }
        final d = snap.data;
        if (d == null) {
          return _kartu(const [
            Text('Belum ada alat terdaftar untuk Puskesmas ini.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ]);
        }

        final aktif = d.status == 'aktif';
        return _kartu([
          const Text('Info Alat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          _baris('Kode alat', _teks(d.id)),
          _baris(
            'Status',
            Row(children: [
              Icon(Icons.circle, size: 10, color: aktif ? statusColor('normal') : AppColors.muted),
              const SizedBox(width: 6),
              _teks(d.status.isEmpty ? '-' : d.status),
            ]),
          ),
          _baris('Sensor utama', _teks(d.sensorUtama ?? '-')),
          const Divider(height: 22),
          const Text('Kalibrasi Aktif',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          if (d.kalibrasiAktifId == null)
            const Text('Belum ada kalibrasi aktif. Catat atau pilih kalibrasi lewat tombol di bawah.',
                style: TextStyle(color: AppColors.muted, fontSize: 13))
          else
            StreamBuilder<Kalibrasi?>(
              stream: widget.svc.kalibrasiAktif(d.id, d.kalibrasiAktifId!),
              builder: (context, ks) {
                if (ks.hasError) return ErrorBox(ks.error!);
                final k = ks.data;
                if (k == null) {
                  return Text('Dokumen kalibrasi ${d.kalibrasiAktifId} tidak ditemukan.',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13));
                }
                final hari = k.tanggal == null ? null : DateTime.now().difference(k.tanggal!).inDays;
                final lama = hari != null && hari > kBatasHariKalibrasi;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _baris('ID', _teks(k.id)),
                  _baris('Tanggal',
                      _teks(k.tanggal == null ? '-' : '${fmtTanggal(k.tanggal!)} ($hari hari lalu)')),
                  _baris('Koefisien a / b', _teks('${_n(k.koefisienA)} / ${_n(k.koefisienB)}')),
                  _baris('Intensitas awal (I0)', _teks('${_n(k.nilaiLux)} lux')),
                  _baris('Alpha', _teks(_n(k.alpha))),
                  _baris('Diameter', _teks('${_n(k.diameter)} cm')),
                  _baris('Rumus', _teks(k.rumusVersi)),
                  if (lama)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF1DC), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.orange2),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Kalibrasi sudah $hari hari. Pertimbangkan kalibrasi ulang.',
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                      ]),
                    ),
                ]);
              },
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => KalibrasiScreen(svc: widget.svc))),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Kelola Kalibrasi'),
            ),
          ),
        ]);
      },
    );
  }
}
