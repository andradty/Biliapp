import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'kartu_alat.dart';
import 'mulai_pemeriksaan_screen.dart';
import 'status_alat.dart';

/// Tab Alat: status koneksi, info + kalibrasi alat, dan mulai pemeriksaan.
class AdminAlat extends StatefulWidget {
  final DataService svc;
  const AdminAlat({super.key, required this.svc});

  @override
  State<AdminAlat> createState() => _AdminAlatState();
}

class _AdminAlatState extends State<AdminAlat> {
  String? _pasienId;

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
            StatusAlatBar(svc: widget.svc),
            const SizedBox(height: 12),
            KartuInfoAlat(svc: widget.svc),
            const SectionLabel('Mulai Pemeriksaan'),
            StreamBuilder<List<Pasien>>(
              stream: widget.svc.pasienPuskesmas(),
              builder: (context, snap) {
                final list = snap.data ?? <Pasien>[];
                return DropdownButtonFormField<String>(
                  initialValue: _pasienId,
                  decoration: InputDecoration(
                    labelText: 'Pilih pasien',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: [
                    for (final p in list) DropdownMenuItem(value: p.id, child: Text(p.nama))
                  ],
                  onChanged: (v) => setState(() => _pasienId = v),
                );
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
          ]),
        ),
      ]),
    );
  }
}
