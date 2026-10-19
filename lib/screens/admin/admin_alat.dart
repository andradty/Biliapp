import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Placeholder: alur sesi pemeriksaan (RTDB) menyusul setelah firmware siap.
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
            child: Text('Alat',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.circle, size: 12, color: AppColors.muted),
                SizedBox(width: 10),
                Expanded(child: Text('Status alat: belum terhubung (menunggu integrasi firmware)')),
              ]),
            ),
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
                  : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Belum tersambung ke perangkat. Menunggu firmware.'))),
            ),
          ]),
        ),
      ]),
    );
  }
}
