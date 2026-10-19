import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../riwayat_pasien_screen.dart';

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
            child: Text('Anak',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
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
              return ListView(padding: const EdgeInsets.all(20), children: [
                for (final p in list)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const BabyAvatar(),
                      title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(p.usia, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatPasienScreen(
                              pasien: p, stream: svc.pemeriksaanAnak(pasienId: p.id)),
                        ),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
