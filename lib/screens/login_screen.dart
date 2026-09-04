import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  String? _type;

  bool get _canLogin =>
      _phone.text.length == 11 && _pass.text.isNotEmpty && _type != null;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: -70, left: -70, child: _circle(const Color(0xFF3EC6C0))),
            Positioned(bottom: -90, right: -90, child: _circle(const Color(0xFFE8A33D))),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill(Icons.language_rounded, AppColors.teal,
                          s.isArabic ? 'English' : 'العربية', s.toggleLanguage),
                      const SizedBox(width: 10),
                      _pill(Icons.nightlight_round, AppColors.orange,
                          s.tr('darkMode'), s.toggleDark),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                                  colors: [AppColors.orange, AppColors.teal])
                              .createShader(r),
                          child: const Icon(Icons.waves_rounded,
                              size: 80, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.tr('appName'),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(s.tr('appNameSub'),
                            style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(height: 20),
                        _accountType(s),
                        const SizedBox(height: 14),
                        _field(s, _phone, 'phoneNumber', Icons.person_rounded,
                            keyboard: TextInputType.phone, maxLength: 11),
                        const SizedBox(height: 14),
                        _field(s, _pass, 'password', Icons.lock_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white70),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            )),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _canLogin ? AppColors.orange : Colors.grey.shade500,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _canLogin ? s.login : null,
                            child: Text(s.tr('login'),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.tr('noAccount'),
                            style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 6),
                        Text(s.tr('signUp'),
                            style: const TextStyle(
                                color: AppColors.orange, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(Color c) => Container(
        width: 240, height: 240,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.withAlpha(25)),
      );

  Widget _pill(IconData ic, Color c, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, color: c, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _accountType(AppSettings s) => Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: Theme.of(context).colorScheme.surface,
            value: _type,
            hint: Text(s.tr('accountType'), style: TextStyle(color: Colors.grey.shade400)),
            items: ['customer', 'agent']
                .map((t) => DropdownMenuItem(value: t, child: Text(s.tr(t))))
                .toList(),
            onChanged: (v) => setState(() => _type = v),
          ),
        ),
      );

  Widget _field(AppSettings s, TextEditingController c, String hintKey, IconData ic,
          {TextInputType? keyboard, int? maxLength, bool obscure = false, Widget? suffix}) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        maxLength: maxLength,
        obscureText: obscure,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: s.tr(hintKey),
          prefixIcon: Icon(ic, color: Colors.white70),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade700)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.teal)),
          counterStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      );
}
