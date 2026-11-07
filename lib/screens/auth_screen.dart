import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AuthScreen({super.key, this.onBack});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _svc = AuthService();
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _hp = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  String? _error;
  int _gagal = 0;
  String _gagalEmail = '';
  bool _resetBusy = false;

  @override
  void dispose() {
    _nama.dispose();
    _hp.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await _svc.register(
            nama: _nama.text.trim(),
            nohp: _hp.text.trim(),
            email: _email.text.trim(),
            password: _pass.text);
      } else {
        await _svc.login(_email.text.trim(), _pass.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!_register && AuthService.salahKredensial(e)) {
            final em = _email.text.trim().toLowerCase();
            _gagal = em == _gagalEmail ? _gagal + 1 : 1;
            _gagalEmail = em;
          }
          _error = AuthService.pesanError(e);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMode(bool reg) => setState(() {
        _register = reg;
        _error = null;
        _gagal = 0;
      });

  Future<void> _lupaPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Isi email yang terdaftar dulu, lalu tekan "Lupa password?".');
      return;
    }
    setState(() {
      _resetBusy = true;
      _error = null;
    });
    try {
      await _svc.kirimResetPassword(email);
      if (!mounted) return;
      setState(() => _gagal = 0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Jika $email terdaftar, link reset password sudah dikirim. '
            'Cek inbox atau folder spam.'),
        duration: const Duration(seconds: 6),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _resetBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: bgGradient,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.onBack != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 36,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.arrow_back, color: AppColors.teal),
                              onPressed: widget.onBack,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Center(
                        child: Image.asset(
                          'assets/logo-bilicheck.png',
                          width: 248,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Segment(register: _register, onChanged: _setMode),
                      const SizedBox(height: 22),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_register) ...[
                              _Field(
                                label: 'Full Name',
                                controller: _nama,
                                action: TextInputAction.next,
                                validator: (v) =>
                                    (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                              ),
                              _Field(
                                label: 'No. HP (opsional untuk Orang Tua)',
                                controller: _hp,
                                keyboard: TextInputType.phone,
                                action: TextInputAction.next,
                              ),
                            ],
                            _Field(
                              label: 'Email',
                              controller: _email,
                              keyboard: TextInputType.emailAddress,
                              action: TextInputAction.next,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Email wajib diisi';
                                if (!s.contains('@')) return 'Format email tidak valid';
                                return null;
                              },
                            ),
                            _Field(
                              label: 'Password',
                              controller: _pass,
                              obscure: _hide,
                              action: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                icon: Icon(
                                  _hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.muted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _hide = !_hide),
                              ),
                              validator: (v) {
                                final s = v ?? '';
                                if (s.isEmpty) return 'Password wajib diisi';
                                if (_register && s.length < 6) {
                                  return 'Minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      if (!_register)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetBusy ? null : _lupaPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(top: 2, bottom: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: _resetBusy
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Lupa password?',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13,
                                ),
                              ),
                              if (!_register && _gagal >= 2) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _resetBusy ? null : _lupaPassword,
                                  child: const Text(
                                    'Lupa password akun ini? Kirim link reset.',
                                    style: TextStyle(
                                      color: Color(0xFFB71C1C),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _GradientButton(
                        label: _register ? 'Daftar' : 'Masuk',
                        busy: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool register;
  final ValueChanged<bool> onChanged;
  const _Segment({required this.register, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E3E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: register ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: register
                      ? const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: register ? FontWeight.w700 : FontWeight.w500,
                    color: register ? const Color(0xFF0A6D88) : const Color(0xFF6E7781),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !register ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: !register
                      ? const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: !register ? FontWeight.w700 : FontWeight.w500,
                    color: !register ? const Color(0xFF0A6D88) : const Color(0xFF6E7781),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboard,
    this.action,
    this.onSubmitted,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232B38),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E2EC), width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              obscuringCharacter: '•',
              keyboardType: keyboard,
              textInputAction: action,
              onFieldSubmitted: onSubmitted,
              validator: validator,
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: suffix,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _GradientButton({required this.label, this.busy = false, this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFAF36), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      );
}
