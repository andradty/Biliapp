import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class TambahPasienSheet extends StatefulWidget {
  final DataService svc;
  const TambahPasienSheet({super.key, required this.svc});

  @override
  State<TambahPasienSheet> createState() => _TambahPasienSheetState();
}

class _TambahPasienSheetState extends State<TambahPasienSheet> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _berat = TextEditingController();
  final _usia = TextEditingController();
  final _alamat = TextEditingController();
  final _emailOrtu = TextEditingController();
  DateTime? _lahir;
  String _jk = 'L';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nama, _berat, _usia, _alamat, _emailOrtu]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _lahir ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (d != null) setState(() => _lahir = d);
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    if (_lahir == null) {
      setState(() => _error = 'Tanggal lahir wajib diisi');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      String? ortuId;
      if (_emailOrtu.text.trim().isNotEmpty) {
        if (!_emailOrtu.text.contains('@')) {
          setState(() {
            _busy = false;
            _error = 'Format email Orang Tua tidak valid.';
          });
          return;
        }
        ortuId = await widget.svc.cariOrangTua(_emailOrtu.text);
        if (ortuId == null) {
          setState(() {
            _busy = false;
            _error = 'Orang Tua dengan email itu belum terdaftar. '
                'Kosongkan kolom untuk menyimpan tanpa menautkan.';
          });
          return;
        }
      }
      // tanpa await: tersimpan di cache lokal dan tersinkron saat online
      widget.svc
          .tambahPasien(
            nama: _nama.text,
            lahir: _lahir!,
            jenisKelamin: _jk,
            beratLahir: int.parse(_berat.text),
            usiaKehamilan: int.parse(_usia.text),
            alamat: _alamat.text,
            orangTuaId: ortuId,
          )
          .catchError((Object e) {
        messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan pasien: $e')));
      });
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Pasien disimpan')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Gagal: $e';
        });
      }
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  String? _wajib(String? v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null;
  String? _beratValid(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Isi angka';
    if (n < 300 || n > 7000) return 'Berat harus 300-7000 gram';
    return null;
  }

  String? _usiaValid(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Isi angka';
    if (n < 20 || n > 45) return 'Usia harus 20-45 minggu';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Tambah Pasien',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextFormField(controller: _nama, decoration: _dec('Nama bayi'), validator: _wajib),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pilihTanggal,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_lahir == null ? 'Pilih tanggal lahir' : fmtTanggal(_lahir!)),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'L', label: Text('Laki-laki')),
                  ButtonSegment(value: 'P', label: Text('Perempuan')),
                ],
                selected: {_jk},
                onSelectionChanged: (s) => setState(() => _jk = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _berat,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('Berat lahir').copyWith(
                    suffixText: 'gram',
                    helperText: 'Dalam GRAM, bukan kg. Contoh: 3200'),
                validator: _beratValid,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usia,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('Usia kehamilan').copyWith(
                    suffixText: 'minggu',
                    helperText: 'Dalam MINGGU, bukan bulan. Contoh: 38'),
                validator: _usiaValid,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _alamat, decoration: _dec('Alamat'), validator: _wajib),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailOrtu,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: _dec('Email Orang Tua (opsional, untuk menautkan)'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
                ),
              const SizedBox(height: 18),
              GradientButton(label: _busy ? 'Menyimpan...' : 'Simpan', onPressed: _busy ? null : _simpan),
            ]),
          ),
        ),
      ),
    );
  }
}
