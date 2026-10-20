import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
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
  late final Stream<List<Pemeriksaan>> _s30 = widget.svc.pemeriksaan30Hari();

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
                    stream: widget.svc.puskesmas(),
                    builder: (c, s) => Text(
                      (s.data?.data()?['nama'] ?? widget.user.puskesmasId ?? '') as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.notifications, color: AppColors.orange1),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Pasien>>(
              stream: widget.svc.pasienPuskesmas(),
              builder: (context, ps) {
                if (ps.hasError) return SingleChildScrollView(child: ErrorBox(ps.error!));
                final pasien = {for (final p in ps.data ?? <Pasien>[]) p.id: p};
                return StreamBuilder<List<Pemeriksaan>>(
                  stream: widget.svc.pemeriksaanTerakhir(),
                  builder: (context, es) {
                    if (es.hasError) return SingleChildScrollView(child: ErrorBox(es.error!));
                    if (!es.hasData) return const Center(child: CircularProgressIndicator());
                    final q = _q.trim().toLowerCase();
                    final list = es.data!
                        .where((e) =>
                            q.isEmpty ||
                            (pasien[e.pasienId]?.nama.toLowerCase().contains(q) ?? false))
                        .toList();
                    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
                      SearchField(hint: 'Cari nama...', onChanged: (v) => setState(() => _q = v)),
                      const SizedBox(height: 14),
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
                            stream: widget.svc.jumlahHariIni(),
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
                            ? RingkasanAdmin(data: s30.data!, pasien: pasien, svc: widget.svc)
                            : const SizedBox.shrink(),
                      ),
                      const SectionLabel('Pemeriksaan Terakhir'),
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
                          title: pasien[e.pasienId]?.nama ?? 'Pasien',
                          subtitle: fmtTanggalPendek(e.waktu),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HasilScreen(
                                  p: e, namaPasien: pasien[e.pasienId]?.nama ?? 'Pasien'),
                            ),
                          ),
                        ),
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