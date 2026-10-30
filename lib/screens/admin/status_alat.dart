import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/bacaan_alat.dart';
import '../../models/device.dart';
import '../../models/status_alat.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'mulai_pemeriksaan_screen.dart' show kBatasStaleDetik;

/// Indikator koneksi alat di tab Alat. Menampilkan status MQTT & ESP32.
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
    final String espStatus;
    final bool espConnected = _hidup;

    if (_hidup) {
      warna = statusColor('normal');
      teks = 'Alat terhubung';
      espStatus = 'Connected';
    } else if (_segar != null) {
      warna = statusColor('kritis');
      teks = 'Alat tidak mengirim data';
      espStatus = 'Disconnected';
    } else {
      warna = AppColors.muted;
      teks = _n == null ? 'Belum ada data dari alat' : 'Menunggu data dari alat...';
      espStatus = 'Waiting';
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
        const SizedBox(height: 12),
        // Kotak Koneksi ESP & MQTT seperti di desain
        Row(
          children: [
            Expanded(
              child: _BadgeKoneksi(
                title: 'MQTT',
                status: _hidup ? 'Connected' : 'Offline',
                connected: _hidup,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BadgeKoneksi(
                title: 'ESP32',
                status: espStatus,
                connected: espConnected,
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Text(bagian.join(' • '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            );
          },
        ),
      ]),
    );
  }
}

class _BadgeKoneksi extends StatelessWidget {
  final String title;
  final String status;
  final bool connected;

  const _BadgeKoneksi({
    required this.title,
    required this.status,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = connected ? const Color(0xFF16A34A) : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: connected ? const Color(0xFF16A34A) : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
