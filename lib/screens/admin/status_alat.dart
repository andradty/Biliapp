import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/bacaan_alat.dart';
import '../../models/device.dart';
import '../../models/status_alat.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'mulai_pemeriksaan_screen.dart' show kBatasStaleDetik;

/// Indikator koneksi alat di tab Alat. "Terhubung" hanya jika counter `n` pada
/// `devices/{id}/live` berubah dalam [kBatasStaleDetik] detik terakhir.
class StatusAlatBar extends StatefulWidget {
  final DataService svc;
  const StatusAlatBar({super.key, required this.svc});

  @override
  State<StatusAlatBar> createState() => _StatusAlatBarState();
}

class _StatusAlatBarState extends State<StatusAlatBar> {
  late final Stream<DeviceInfo?> _dev = widget.svc.deviceSaya();

  Widget _kotak(Widget isi) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: isi,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceInfo?>(
      stream: _dev,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          return _kotak(const Row(children: [
            Icon(Icons.circle, size: 12, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(child: Text('Status alat: belum ada alat terdaftar')),
          ]));
        }
        return _StatusIsi(svc: widget.svc, deviceId: d.id);
      },
    );
  }
}

class _StatusIsi extends StatefulWidget {
  final DataService svc;
  final String deviceId;
  const _StatusIsi({required this.svc, required this.deviceId});

  @override
  State<_StatusIsi> createState() => _StatusIsiState();
}

class _StatusIsiState extends State<_StatusIsi> {
  late final Stream<StatusAlat?> _status = widget.svc.statusAlat(widget.deviceId);
  StreamSubscription<BacaanAlat?>? _sub;
  Timer? _tick;
  int? _n;
  DateTime? _segar;

  @override
  void initState() {
    super.initState();
    _sub = widget.svc.bacaanLive(widget.deviceId).listen((b) {
      if (!mounted) return;
      setState(() {
        if (b == null) {
          _n = null;
          _segar = null;
          return;
        }
        // Event pertama = nilai lama; segar hanya kalau `n` berubah.
        if (_n != null && b.urut != _n) _segar = DateTime.now();
        _n = b.urut;
      });
    }, onError: (_) {});
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  bool get _hidup =>
      _segar != null && DateTime.now().difference(_segar!).inSeconds <= kBatasStaleDetik;

  @override
  Widget build(BuildContext context) {
    final Color warna;
    final String teks;
    if (_hidup) {
      warna = statusColor('normal');
      teks = 'Alat terhubung';
    } else if (_segar != null) {
      warna = statusColor('kritis');
      teks = 'Alat tidak mengirim data';
    } else {
      warna = AppColors.muted;
      teks = _n == null ? 'Belum ada data dari alat' : 'Menunggu data dari alat...';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.circle, size: 12, color: warna),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Status alat: $teks',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        StreamBuilder<StatusAlat?>(
          stream: _status,
          builder: (context, snap) {
            final s = snap.data;
            if (s == null) return const SizedBox.shrink();
            final bagian = <String>[
              if (s.firmware != null) 'Firmware ${s.firmware}',
              if (s.rssi != null) 'Sinyal ${s.rssi} dBm',
              if (s.lastSeen != null)
                'Terakhir terlihat ${fmtTanggalPendek(s.lastSeen!)} ${fmtJam(s.lastSeen!)}',
            ];
            if (bagian.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6, left: 22),
              child: Text(bagian.join(' • '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            );
          },
        ),
      ]),
    );
  }
}
