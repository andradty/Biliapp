import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'kartu_alat.dart';
import 'mulai_pemeriksaan_screen.dart';
import 'status_alat.dart';

/// Tab Alat: mulai pemeriksaan (paling atas), lalu status koneksi serta info + kalibrasi alat.
class AdminAlat extends StatefulWidget {
  final DataService svc;
  const AdminAlat({super.key, required this.svc});

  @override
  State<AdminAlat> createState() => _AdminAlatState();
}

class _AdminAlatState extends State<AdminAlat> {
  late final Stream<List<Pasien>> _pasienS = widget.svc.pasienPuskesmas();
  String? _pasienId;
  final _cariC = TextEditingController();
  String _cari = '';

  @override
  void dispose() {
    _cariC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        const GradientHeader(
          child: Center(
            child: Text(
              'Alat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SectionLabel('Mulai Pemeriksaan'),
            StreamBuilder<List<Pasien>>(
              stream: _pasienS,
              builder: (context, snap) {
                final list = snap.data ?? <Pasien>[];
                final terpilih = list.where((p) => p.id == _pasienId).toList();

                // Pasien sudah dipilih: tampilkan kartu + tombol ganti.
                if (terpilih.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.child_care_rounded, color: AppColors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(terpilih.first.nama,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _pasienId = null;
                          _cari = '';
                          _cariC.clear();
                        }),
                        child: const Text('Ganti'),
                      ),
                    ]),
                  );
                }

                final q = _cari.trim().toLowerCase();
                final hasil = q.isEmpty
                    ? <Pasien>[]
                    : list.where((p) => p.nama.toLowerCase().contains(q)).take(6).toList();

                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: _cariC,
                    onChanged: (v) => setState(() => _cari = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari nama bayi',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _cari.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _cari = '';
                                _cariC.clear();
                              }),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  if (q.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    if (hasil.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Nama bayi tidak ditemukan.',
                            style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          for (final p in hasil)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.child_care_rounded, color: AppColors.teal),
                              title: Text(p.nama),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _pasienId = p.id);
                              },
                            ),
                        ]),
                      ),
                  ],
                ]);
              },
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: 'Mulai Pemeriksaan',
              onPressed: _pasienId == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MulaiPemeriksaanScreen(
                              svc: widget.svc, pasienId: _pasienId!),
                        ),
                      ),
            ),
            const SectionLabel('Info Alat'),
            StatusAlatBar(svc: widget.svc),
            const SizedBox(height: 12),
            KartuInfoAlat(svc: widget.svc),
          ]),
        ),
      ]),
    );
  }
}
