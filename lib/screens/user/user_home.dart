import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class UserHome extends StatelessWidget {
  final AppUser user;
  final DataService svc;
  final VoidCallback onLihatAnak;
  const UserHome({super.key, required this.user, required this.svc, required this.onLihatAnak});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        GradientHeader(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Welcome!', style: TextStyle(color: Colors.white70)),
                Text(user.nama,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Text('Orang Tua', style: TextStyle(color: Colors.white)),
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
            stream: svc.anakSaya(),
            builder: (context, ps) {
              if (ps.hasError) return SingleChildScrollView(child: ErrorBox(ps.error!));
              if (!ps.hasData) return const Center(child: CircularProgressIndicator());
              final anak = ps.data!;
              return StreamBuilder<List<Pemeriksaan>>(
                stream: svc.pemeriksaanAnak(),
                builder: (context, es) {
                  if (es.hasError) return SingleChildScrollView(child: ErrorBox(es.error!));
                  final semua = es.data ?? <Pemeriksaan>[];
                  return ListView(padding: const EdgeInsets.all(20), children: [
                    if (anak.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Text(
                          'Belum ada anak yang ditautkan ke akun ini. Minta petugas '
                          'Puskesmas menautkan dengan nomor HP yang terdaftar.',
                          style: TextStyle(color: AppColors.muted, height: 1.5),
                        ),
                      ),
                    for (final a in anak)
                      Builder(builder: (context) {
                        final terakhir = semua.where((e) => e.pasienId == a.id).toList();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Expanded(
                              child: Text('Status ${a.nama}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            if (terakhir.isEmpty)
                              const Text('Belum ada pemeriksaan',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted))
                            else
                              StatusBadge(terakhir.first.status),
                          ]),
                        );
                      }),
                    const SizedBox(height: 8),
                    GradientButton(label: 'Lihat Riwayat Anak', onPressed: onLihatAnak),
                    const SectionLabel('Agenda Puskesmas'),
                    // Placeholder: belum ada sumber data agenda di database.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Row(children: [
                        Icon(Icons.event, color: AppColors.teal),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Agenda belum tersedia',
                              style: TextStyle(color: AppColors.muted)),
                        ),
                      ]),
                    ),
                  ]);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
