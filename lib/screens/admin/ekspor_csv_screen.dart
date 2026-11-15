import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/csv_service.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

enum _Mode { mingguan, bulanan, custom }

/// Ekspor pemeriksaan Puskesmas ke CSV: mingguan, bulanan, atau rentang custom.
class EksporCsvScreen extends StatefulWidget {
  final DataService svc;
  const EksporCsvScreen({super.key, required this.svc});

  @override
  State<EksporCsvScreen> createState() => _EksporCsvScreenState();
}

class _EksporCsvScreenState extends State<EksporCsvScreen> {
  _Mode _mode = _Mode.mingguan;
  int _geser = 0; // 0 = periode berjalan, -1 = sebelumnya, dst. (mingguan/bulanan)
  DateTimeRange? _custom;
  String? _pasienId;
  bool _sertakanBatal = false;
  String _pemisah = ';';
  bool _loading = false;

  /// akhir bersifat eksklusif.
  ({DateTime awal, DateTime akhir})? get _rentang {
    final n = DateTime.now();
    switch (_mode) {
      case _Mode.mingguan:
        final senin = DateTime(n.year, n.month, n.day - (n.weekday - 1) + 7 * _geser);
        return (awal: senin, akhir: DateTime(senin.year, senin.month, senin.day + 7));
      case _Mode.bulanan:
        return (
          awal: DateTime(n.year, n.month + _geser, 1),
          akhir: DateTime(n.year, n.month + _geser + 1, 1),
        );
      case _Mode.custom:
        final c = _custom;
        if (c == null) return null;
        return (
          awal: DateTime(c.start.year, c.start.month, c.start.day),
          akhir: DateTime(c.end.year, c.end.month, c.end.day + 1),
        );
    }
  }

  String get _label {
    final r = _rentang;
    if (r == null) return 'Pilih rentang tanggal';
    final akhir = DateTime(r.akhir.year, r.akhir.month, r.akhir.day - 1);
    return '${fmtTanggal(r.awal)} - ${fmtTanggal(akhir)}';
  }

  Future<void> _pilihCustom() async {
    final n = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(n.year, n.month, n.day),
      initialDateRange: _custom,
    );
    if (r != null) setState(() => _custom = r);
  }

  Future<void> _ekspor() async {
    final r = _rentang;
    if (r == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final data = await widget.svc.pemeriksaanRentang(r.awal, r.akhir, pasienId: _pasienId);
      final pasien = await widget.svc.pasienPuskesmas().first;
      final nama = {for (final p in pasien) p.id: p.nama};
      final tampil = _sertakanBatal ? data : data.where((e) => !e.dibatalkan).toList();
      if (tampil.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('Tidak ada data pada periode ini.')));
        return;
      }
      final csv = CsvService.buat(data, nama, pemisah: _pemisah, sertakanDibatalkan: _sertakanBatal);
      String t(DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      final akhir = DateTime(r.akhir.year, r.akhir.month, r.akhir.day - 1);
      await CsvService.bagikan(csv, 'BiliCheck_Pemeriksaan_${t(r.awal)}_${t(akhir)}.csv');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bisaMaju = _mode != _Mode.custom && _geser < 0;
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Ekspor Data CSV'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const SectionLabel('PERIODE'),
              SegmentedButton<_Mode>(
                segments: const [
                  ButtonSegment(value: _Mode.mingguan, label: Text('Mingguan')),
                  ButtonSegment(value: _Mode.bulanan, label: Text('Bulanan')),
                  ButtonSegment(value: _Mode.custom, label: Text('Custom')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _geser = 0;
                }),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration:
                    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  if (_mode != _Mode.custom)
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _geser--),
                    ),
                  Expanded(
                    child: _mode == _Mode.custom
                        ? TextButton.icon(
                            onPressed: _pilihCustom,
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(_label),
                          )
                        : Text(_label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if (_mode != _Mode.custom)
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: bisaMaju ? () => setState(() => _geser++) : null,
                    ),
                ]),
              ),
              if (_mode == _Mode.mingguan)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text('Satu minggu = Senin sampai Minggu.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              const SectionLabel('PASIEN'),
              StreamBuilder<List<Pasien>>(
                stream: widget.svc.pasienPuskesmas(),
                builder: (context, snap) {
                  final list = snap.data ?? <Pasien>[];
                  return DropdownButtonFormField<String?>(
                    initialValue: _pasienId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Semua pasien')),
                      for (final p in list)
                        DropdownMenuItem<String?>(value: p.id, child: Text(p.nama)),
                    ],
                    onChanged: (v) => setState(() => _pasienId = v),
                  );
                },
              ),
              const SectionLabel('FORMAT'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: ';', label: Text('Excel Indonesia (;)')),
                  ButtonSegment(value: ',', label: Text('Standar (,)')),
                ],
                selected: {_pemisah},
                onSelectionChanged: (s) => setState(() => _pemisah = s.first),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sertakan pemeriksaan dibatalkan'),
                subtitle: const Text('Ditandai kolom dibatalkan = ya'),
                value: _sertakanBatal,
                onChanged: (v) => setState(() => _sertakanBatal = v),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: _loading ? 'Menyiapkan...' : 'Ekspor CSV',
                onPressed: (_loading || _rentang == null) ? null : _ekspor,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
