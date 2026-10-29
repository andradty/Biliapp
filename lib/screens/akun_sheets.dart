import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

void bukaUbahProfil(BuildContext context, AppUser user) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UbahProfilSheet(user: user),
    );

void bukaGantiPassword(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GantiPasswordSheet(),
    );

Widget _bungkus(BuildContext context, Widget isi) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: isi),
      ),
    );

class _UbahProfilSheet extends StatefulWidget {
  final AppUser user;
  const _UbahProfilSheet({required this.user});

  @override
  State<_UbahProfilSheet> createState() => _UbahProfilSheetState();
}

class _UbahProfilSheetState extends State<_UbahProfilSheet> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.user.nama);
  late final _hp = TextEditingController(text: widget.user.nohp);

  @override
  void dispose() {
    _nama.dispose();
    _hp.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    // Tidak di-await: saat offline masuk antrean lokal.
    AuthService()
        .ubahProfil(uid: widget.user.uid, nama: _nama.text, nohp: _hp.text)
        .catchError((e) => messenger
            .showSnackBar(SnackBar(content: Text(AuthService.pesanError(e)))));
    messenger.showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _bungkus(
      context,
      Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ubah Profil',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
            validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Nama minimal 2 karakter',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hp,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Nomor Telepon', hintText: '08xxxxxxxxxx', border: OutlineInputBorder()),
            validator: (v) =>
                RegExp(r'^08\d{8,12}$').hasMatch((v ?? '').trim()) ? null : 'Format 08xxxxxxxxxx',
          ),
          const SizedBox(height: 6),
          const Text('Email tidak dapat diubah dari aplikasi.',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          GradientButton(label: 'Simpan', onPressed: _simpan),
        ]),
      ),
    );
  }
}

class _GantiPasswordSheet extends StatefulWidget {
  const _GantiPasswordSheet();

  @override
  State<_GantiPasswordSheet> createState() => _GantiPasswordSheetState();
}

class _GantiPasswordSheetState extends State<_GantiPasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();
  bool _lihat = false;
  bool _proses = false;
  String? _error;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _proses = true;
      _error = null;
    });
    try {
      await AuthService().gantiPassword(lama: _lama.text, baru: _baru.text);
      messenger.showSnackBar(const SnackBar(content: Text('Password berhasil diganti.')));
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _proses = false;
        _error = AuthService.salahKredensial(e) ? 'Password lama salah.' : AuthService.pesanError(e);
      });
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_lihat ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _lihat = !_lihat),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _bungkus(
      context,
      Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ganti Password',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lama,
            obscureText: !_lihat,
            decoration: _dec('Password lama'),
            validator: (v) => (v ?? '').isEmpty ? 'Isi password lama' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _baru,
            obscureText: !_lihat,
            decoration: _dec('Password baru'),
            validator: (v) => (v ?? '').length >= 6 ? null : 'Minimal 6 karakter',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ulang,
            obscureText: !_lihat,
            decoration: _dec('Ulangi password baru'),
            validator: (v) => v == _baru.text ? null : 'Password tidak sama',
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
          ],
          const SizedBox(height: 16),
          _proses
              ? const Center(child: CircularProgressIndicator())
              : GradientButton(label: 'Simpan Password', onPressed: _simpan),
        ]),
      ),
    );
  }
}
