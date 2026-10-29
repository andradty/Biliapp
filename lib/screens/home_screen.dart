import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'admin/admin_shell.dart';
import 'user/user_shell.dart';

/// Memilih tampilan sesuai role di users/{uid}.
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) =>
      user.isPetugas ? AdminShell(user: user) : UserShell(user: user);
}
