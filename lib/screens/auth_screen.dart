import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            nama: _nama.text, nohp: _hp.text, email: _email.text, password: _pass.text);
      } else {
        await _svc.login(_email.text, _pass.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMode(bool reg) => setState(() {
        _register = reg;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: widget.onBack,
                          ),
                        ),
                      SvgPicture.asset('assets/logo.svg', height: 110),
                      const SizedBox(height: 32),
                      _Segment(register: _register, onChanged: _setMode),
                      const SizedBox(height: 8),
                      if (_register) ...[
                        _Field(
                          label: 'Full Name',
                          controller: _nama,
                          action: TextInputAction.next,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        _Field(
                          label: 'No. HP',
                          controller: _hp,
                          keyboard: TextInputType.phone,
                          action: TextInputAction.next,
                          validator: (v) => RegExp(r'^08\d{8,12}$')
                                  .hasMatch((v ?? '').trim())
                              ? null
                              : 'Gunakan format 08xxxxxxxxxx',
                        ),
                      ],
                      _Field(
                        label: 'Email',
                        controller: _email,
                        keyboard: TextInputType.emailAddress,
                        action: TextInputAction.next,
                        validator: (v) => (v ?? '').contains('@') ? null : 'Email tidak valid',
                      ),
                      _Field(
                        label: 'Password',
                        controller: _pass,
                        obscure: _hide,
                        action: TextInputAction.done,
                        onSubmit: (_) => _submit(),
                        suffix: IconButton(
                          icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                        validator: (v) =>
                            (v ?? '').length >= 6 ? null : 'Minimal 6 karakter',
                      ),
                      const SizedBox(height: 20),
                      _GradientButton(
                        label: _register ? 'Daftar' : 'Masuk',
                        busy: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
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
    Widget tab(String t, bool reg) {
      final on = register == reg;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(reg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: on
                  ? const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))]
                  : null,
            ),
            child: Text(t,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: on ? AppColors.teal : AppColors.muted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: const Color(0xFFE3E3E3), borderRadius: BorderRadius.circular(999)),
      child: Row(children: [tab('Register', true), tab('Login', false)]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmit;

  const _Field({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboard,
    this.action,
    this.obscure = false,
    this.suffix,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDCE6EC)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboard,
          textInputAction: action,
          obscureText: obscure,
          onFieldSubmitted: onSubmit,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: AppColors.teal2, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _GradientButton({required this.label, required this.busy, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: [AppColors.orange1, AppColors.orange2]),
          boxShadow: const [
            BoxShadow(color: Color(0x44FF8A00), blurRadius: 18, offset: Offset(0, 8))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
