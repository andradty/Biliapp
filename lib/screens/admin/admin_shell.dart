import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/data_service.dart';
import '../../widgets/common.dart';
import '../akun_screen.dart';
import 'admin_alat.dart';
import 'admin_home.dart';
import 'admin_pasien.dart';
import 'tambah_pasien_sheet.dart';

class AdminShell extends StatefulWidget {
  final AppUser user;
  const AdminShell({super.key, required this.user});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;
  late final DataService _svc = DataService(widget.user);

  void _tambah() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TambahPasienSheet(svc: _svc),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        AdminHome(user: widget.user, svc: _svc, onTambah: _tambah),
        AdminPasien(svc: _svc, onTambah: _tambah),
        AdminAlat(svc: _svc),
        AkunScreen(
          user: widget.user,
          onBack: () => setState(() => _i = 0), // Kembali ke tab Home (Beranda Admin)
        ),
      ]),
      bottomNavigationBar: BottomNav(
        index: _i,
        onTap: (i) => setState(() => _i = i),
        items: const [
          NavItem(Icons.home_rounded, 'Home'),
          NavItem(Icons.child_care_rounded, 'Pasien'),
          NavItem(Icons.tune_rounded, 'Alat'),
          NavItem(Icons.account_circle_outlined, 'Akun'),
        ],
      ),
    );
  }
}
