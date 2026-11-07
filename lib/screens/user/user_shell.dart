import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/data_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/common.dart';
import '../akun_screen.dart';
import 'user_anak.dart';
import 'user_home.dart';

class UserShell extends StatefulWidget {
  final AppUser user;
  const UserShell({super.key, required this.user});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _i = 0;
  late final DataService _svc = DataService(widget.user);

  @override
  void initState() {
    super.initState();
    FcmService.instance.init(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        UserHome(
          user: widget.user,
          svc: _svc,
          onLihatAnak: () => setState(() => _i = 1),
          onMulaiSkrining: () => setState(() => _i = 1),
        ),
        UserAnak(svc: _svc),
        AkunScreen(
          user: widget.user,
          onBack: () => setState(() => _i = 0), // Kembali ke tab Home (Beranda User)
        ),
      ]),
      bottomNavigationBar: BottomNav(
        index: _i,
        onTap: (i) => setState(() => _i = i),
        items: const [
          NavItem(Icons.home_rounded, 'Home'),
          NavItem(Icons.child_care_rounded, 'Anak'),
          NavItem(Icons.account_circle_outlined, 'Akun'),
        ],
      ),
    );
  }
}
