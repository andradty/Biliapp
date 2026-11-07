import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

void bukaUbahNama(BuildContext context, AppUser user) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UbahNamaSheet(user: user),
    );

void bukaUbahTelepon(BuildContext context, AppUser user) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UbahTeleponSheet(user: user),
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

/// Modal sheet khusus untuk mengubah Username / Nama saja
class _UbahNamaSheet extends StatefulWidget {
  final AppUser user;
  const _UbahNamaSheet({required this.user});

  @override
  State<_UbahNamaSheet> createState() => _UbahNamaSheetState();
}

class _UbahNamaSheetState extends State<_UbahNamaSheet> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.user.nama);
  bool _busy = false;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService().ubahProfil(
        uid: widget.user.uid,
        nama: _nama.text,
        nohp: widget.user.nohp,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Nama berhasil diperbarui.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AuthService.pesanError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _bungkus(
      context,
      Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Nama',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Username / Nama Lengkap',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().length >= 2 ? null : 'Nama minimal 2 karakter',
            ),
            const SizedBox(height: 20),
            _busy
                ? const Center(child: CircularProgressIndicator())
                : GradientButton(label: 'Simpan Perubahan', onPressed: _simpan),
          ],
        ),
      ),
    );
  }
}

/// Modal sheet khusus untuk mengubah Nomor Telepon saja
class _UbahTeleponSheet extends StatefulWidget {
  final AppUser user;
  const _UbahTeleponSheet({required this.user});

  @override
  State<_UbahTeleponSheet> createState() => _UbahTeleponSheetState();
}

class _UbahTeleponSheetState extends State<_UbahTeleponSheet> {
  final _form = GlobalKey<FormState>();
  late final _hp = TextEditingController(text: widget.user.nohp);
  bool _busy = false;

  @override
  void dispose() {
    _hp.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService().ubahProfil(
        uid: widget.user.uid,
        nama: widget.user.nama,
        nohp: _hp.text,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Nomor telepon berhasil diperbarui.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AuthService.pesanError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _bungkus(
      context,
      Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Nomor Telepon',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hp,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: '08xxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                return RegExp(r'^08\d{8,12}$').hasMatch(s)
                    ? null
                    : 'Format nomor 08xxxxxxxxxx';
              },
            ),
            const SizedBox(height: 20),
            _busy
                ? const Center(child: CircularProgressIndicator())
                : GradientButton(label: 'Simpan Perubahan', onPressed: _simpan),
          ],
        ),
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
  bool _busy = false;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService().gantiPassword(lama: _lama.text, baru: _baru.text);
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Password berhasil diubah.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(AuthService.pesanError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _bungkus(
      context,
      Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ganti Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lama,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama', border: OutlineInputBorder()),
              validator: (v) => (v ?? '').isEmpty ? 'Isi password lama' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baru,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()),
              validator: (v) => (v ?? '').length >= 6 ? null : 'Minimal 6 karakter',
            ),
            const SizedBox(height: 18),
            _busy
                ? const Center(child: CircularProgressIndicator())
                : GradientButton(label: 'Ganti Password', onPressed: _simpan),
          ],
        ),
      ),
    );
  }
}
