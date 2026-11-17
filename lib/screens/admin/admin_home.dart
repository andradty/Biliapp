import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/notification_bell.dart';
import '../hasil_screen.dart';
import 'ringkasan_admin.dart';

class AdminHome extends StatefulWidget {
  final AppUser user;
  final DataService svc;
  final VoidCallback onTambah;
  const AdminHome({super.key, required this.user, required this.svc, required this.onTambah});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String _q = '';
  int _hal = 0;
  static const _perHal = 5;
  // Stream di-cache supaya tidak berlangganan ulang tiap build (penyebab daftar
  // berkedip, scroll lompat ke atas, dan kolom pencarian terhapus).
  late final Stream<List<Pasien>> _pasienS = widget.svc.pasienPuskesmas();
  late final Stream<List<Pemeriksaan>> _terakhirS = widget.svc.pemeriksaanTerakhir();
  late final Stream<int> _hariIniS = widget.svc.jumlahHariIni();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _pkmS = widget.svc.puskesmas();
  late final Stream<List<Pemeriksaan>> _s30 = widget.svc.pemeriksaan30Hari();
  // Data lebih panjang (~6 bulan) khusus grafik per minggu/bulan.
  late final Stream<List<Pemeriksaan>> _sGrafik = widget.svc.pemeriksaan30Hari(hari: 190);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_home',
        backgroundColor: AppColors.orange2,
        foregroundColor: Colors.white,
        onPressed: widget.onTambah,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          GradientHeader(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Welcome!', style: TextStyle(color: Colors.white70)),
                  Text(widget.user.nama,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _pkmS,
                    builder: (c, s) => Text(
                      (s.data?.data()?['nama'] ?? widget.user.puskesmasId ?? '') as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ]),
              ),
              NotificationBell(user: widget.user, svc: widget.svc),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Pasien>>(
              stream: _pasienS,
              builder: (context, ps) {
                if (ps.hasError) return SingleChildScrollView(child: ErrorBox(ps.error!));
                final pasien = {for (final p in ps.data ?? <Pasien>[]) p.id: p};
                return StreamBuilder<List<Pemeriksaan>>(
                  stream: _terakhirS,
                  builder: (context, es) {
                    if (es.hasError) return SingleChildScrollView(child: ErrorBox(es.error!));
                    if (!es.hasData) return const Center(child: CircularProgressIndicator());
                    final q = _q.trim().toLowerCase();
                    final list = es.data!
                        .where((e) =>
                            q.isEmpty ||
                            (pasien[e.pasienId]?.nama.toLowerCase().contains(q) ?? false))
                        .toList();
                    final total = (list.length / _perHal).ceil();
                    final hal = total == 0 ? 0 : _hal.clamp(0, total - 1).toInt();
                    final tampil = list.skip(hal * _perHal).take(_perHal).toList();
                    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                              colors: [AppColors.teal2, AppColors.teal]),
                        ),
                        child: Row(children: [
                          const Icon(Icons.bar_chart, color: AppColors.orange1),
                          const SizedBox(width: 10),
                          StreamBuilder<int>(
                            stream: _hariIniS,
                            builder: (c, s) => Text('Hari ini: ${s.data ?? 0} Skrining',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ),
                        ]),
                      ),
                      StreamBuilder<List<Pemeriksaan>>(
                        stream: _s30,
                        builder: (c, s30) => s30.hasData
                            ? StreamBuilder<List<Pemeriksaan>>(
                                stream: _sGrafik,
                                builder: (c, sg) => RingkasanAdmin(
                                    data: s30.data!,
                                    dataGrafik: sg.data ?? s30.data!,
                                    pasien: pasien,
                                    svc: widget.svc),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SectionLabel('Pemeriksaan Terakhir'),
                      SearchField(hint: 'Cari nama...', onChanged: (v) => setState(() {
                        _q = v;
                        _hal = 0;
                      })),
                      const SizedBox(height: 12),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Belum ada pemeriksaan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted)),
                        ),
                      for (final e in tampil)
                        PemeriksaanTile(
                          p: e,
                          title: pasien[e.pasienId]?.nama ?? 'Pasien',
                          subtitle: fmtTanggalPendek(e.waktu),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HasilScreen(
                                  p: e,
                                  namaPasien: pasien[e.pasienId]?.nama ?? 'Pasien',
                                  svc: widget.svc),
                            ),
                          ),
                        ),
                      PaginasiBar(
                          halaman: hal, total: total, onUbah: (h) => setState(() => _hal = h)),
                    ]);
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}