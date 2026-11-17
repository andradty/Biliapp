import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../riwayat_pasien_screen.dart';
import 'edit_pasien_sheet.dart';

class AdminPasien extends StatefulWidget {
  final DataService svc;
  final VoidCallback onTambah;
  const AdminPasien({super.key, required this.svc, required this.onTambah});

  @override
  State<AdminPasien> createState() => _AdminPasienState();
}

class _AdminPasienState extends State<AdminPasien> {
  String _q = '';
  int _hal = 0;
  late final Stream<List<Pasien>> _pasienS = widget.svc.pasienPuskesmas();
  static const _perHal = 5;

  void _edit(Pasien p) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditPasienSheet(svc: widget.svc, pasien: p),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_pasien',
        backgroundColor: AppColors.orange2,
        foregroundColor: Colors.white,
        onPressed: widget.onTambah,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const GradientHeader(
            child: Center(
              child: Text('Pasien',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pasien>>(
              stream: _pasienS,
              builder: (context, snap) {
                if (snap.hasError) return SingleChildScrollView(child: ErrorBox(snap.error!));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final q = _q.trim().toLowerCase();
                final list =
                snap.data!.where((p) => q.isEmpty || p.nama.toLowerCase().contains(q)).toList();
                final total = (list.length / _perHal).ceil();
                final hal = total == 0 ? 0 : _hal.clamp(0, total - 1).toInt();
                final tampil = list.skip(hal * _perHal).take(_perHal).toList();
                return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 90), children: [
                  SearchField(hint: 'Cari nama...', onChanged: (v) => setState(() {
                    _q = v;
                    _hal = 0;
                  })),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada pasien. Tekan + untuk menambah.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                    ),
                  for (final p in tampil)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Material(type: MaterialType.transparency, child: ListTile(
                        leading: const BabyAvatar(),
                        title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${p.usia} • ${p.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}'
                                '${p.orangTuaId == null ? ' • belum ditautkan' : ''}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: 'Edit pasien',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.muted),
                            onPressed: () => _edit(p),
                          ),
                          p.pending
                              ? const Icon(Icons.cloud_off, size: 18, color: AppColors.muted)
                              : const Icon(Icons.chevron_right),
                        ]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiwayatPasienScreen(
                                pasien: p, stream: widget.svc.riwayatPasien(p.id), svc: widget.svc),
                          ),
                        ),
                      )),
                    ),
                  PaginasiBar(
                      halaman: hal, total: total, onUbah: (h) => setState(() => _hal = h)),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}