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
  String? _pasienNama;
  bool _modePilihPasien = false;
  bool _sertakanBatal = false;
  String _pemisah = ';';
  bool _loading = false;

  /// Segmen terpilih diberi warna (tanpa ikon centang).
  ButtonStyle get _gayaSegmen => ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? AppColors.teal : Colors.white),
        foregroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? Colors.white : AppColors.ink),
      );

  Future<void> _pilihPasien() async {
    final daftar = await widget.svc.pasienPuskesmas().first;
    if (!mounted) return;
    final p = await showModalBottomSheet<Pasien>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PilihPasienSheet(daftar: daftar, terpilihId: _pasienId),
    );
    if (p != null && mounted) {
      setState(() {
        _pasienId = p.id;
        _pasienNama = p.nama;
      });
    }
  }

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
    if (_modePilihPasien && _pasienId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Pilih pasien terlebih dahulu.')));
      return;
    }
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
                showSelectedIcon: false,
                style: _gayaSegmen,
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
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Semua pasien')),
                  ButtonSegment(value: false, label: Text('Pilih pasien')),
                ],
                selected: {!_modePilihPasien},
                showSelectedIcon: false,
                style: _gayaSegmen,
                onSelectionChanged: (sel) {
                  setState(() {
                    _modePilihPasien = !sel.first;
                    if (sel.first) {
                      _pasienId = null;
                      _pasienNama = null;
                    }
                  });
                  if (!sel.first && _pasienId == null) _pilihPasien();
                },
              ),
              if (_modePilihPasien) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _pilihPasien,
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(_pasienNama ?? 'Cari & pilih pasien',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),
                ),
              ],
              const SectionLabel('FORMAT'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: ';', label: Text('Excel Indonesia (;)')),
                  ButtonSegment(value: ',', label: Text('Standar (,)')),
                ],
                selected: {_pemisah},
                showSelectedIcon: false,
                style: _gayaSegmen,
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


/// Modal pencarian pasien untuk ekspor per pasien.
class _PilihPasienSheet extends StatefulWidget {
  final List<Pasien> daftar;
  final String? terpilihId;
  const _PilihPasienSheet({required this.daftar, this.terpilihId});

  @override
  State<_PilihPasienSheet> createState() => _PilihPasienSheetState();
}

class _PilihPasienSheetState extends State<_PilihPasienSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final hasil = widget.daftar.where((p) => q.isEmpty || p.nama.toLowerCase().contains(q)).toList();
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.8),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F8FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration:
                BoxDecoration(color: const Color(0xFFCFD8DC), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          const Text('Pilih Pasien',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          SearchField(hint: 'Cari nama bayi...', onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 10),
          Flexible(
            child: hasil.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Pasien tidak ditemukan.',
                        style: TextStyle(color: AppColors.muted)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: hasil.length,
                    itemBuilder: (_, i) {
                      final p = hasil[i];
                      final sel = p.id == widget.terpilihId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            leading: const BabyAvatar(size: 38),
                            title: Text(p.nama,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: sel
                                ? const Icon(Icons.check_circle, color: AppColors.teal)
                                : null,
                            onTap: () => Navigator.pop(context, p),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
