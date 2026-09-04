import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/github_admin.dart';
import '../core/theme.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  String? _type;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: Stack(
        children: [
          _glow(const Color(0xFF3EC6C0), Alignment.topLeft),
          _glow(const Color(0xFFE8A33D), Alignment.bottomRight),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill(Icons.language_rounded, AppColors.teal,
                          s.isArabic ? 'English' : 'العربية', s.toggleLanguage, null),
                      const SizedBox(width: 10),
                      _pill(Icons.nightlight_round, AppColors.orange,
                          s.tr('darkMode'), s.toggleDark, _openAdmin),
                    ],
                  ),
                  const SizedBox(height: 36),
                  _logo(s),
                  const SizedBox(height: 36),
                  _card(s),
                  const SizedBox(height: 22),
                  _footer(s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color c, Alignment a) => Positioned.fill(
        child: Align(
          alignment: a,
          child: Container(
            width: 320, height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [c.withAlpha(60), c.withAlpha(0)]),
            ),
          ),
        ),
      );

  Widget _pill(IconData ic, Color c, String label, VoidCallback onTap,
          VoidCallback? onLongPress) =>
      GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withAlpha(60)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, color: c, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _logo(AppSettings s) => Center(
        child: Column(children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) =>
                Transform.scale(scale: 1 + _pulse.value * 0.03, child: child),
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.orange.withAlpha(90), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.orange.withAlpha(60), blurRadius: 40)
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.orange, AppColors.teal])
                      .createShader(r),
                  child:
                      const Icon(Icons.waves_rounded, size: 78, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
                    colors: [AppColors.orange, AppColors.teal])
                .createShader(r),
            child: Text(s.tr('appName'),
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 6),
          Text(s.tr('appNameSub'), style: TextStyle(color: Colors.grey.shade400)),
        ]),
      );

  Widget _card(AppSettings s) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.orange.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF26B0F), AppColors.orange]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.orange.withAlpha(80),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  if (_type == 'guest') {
                    s.loginAsGuest();
                  } else {
                    _accountDialog(s);
                  }
                },
                child: Text(
                    _type == 'guest' ? s.tr('continueAsGuest') : s.tr('login'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: s.loginAsGuest,
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: Text(s.tr('continueAsGuest')),
                style: TextButton.styleFrom(foregroundColor: AppColors.teal),
              ),
            ),
          ],
        ),
      );

  Widget _footer(AppSettings s) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.tr('noAccount'), style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _accountDialog(s),
              child: Text(s.tr('signUp'),
                  style: const TextStyle(
                      color: AppColors.orange, fontWeight: FontWeight.w800)),
            ),
          ],
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
            hint: Text(s.tr('accountType'),
                style: TextStyle(color: Colors.grey.shade400)),
            items: ['agent', 'tech', 'guest']
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
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade700)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.teal, width: 2)),
          counterStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      );

  void _accountDialog(AppSettings s) => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withAlpha(70)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppColors.orange.withAlpha(120),
                    AppColors.teal.withAlpha(80)
                  ]),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              Text(s.tr('createAccount'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      color: Colors.grey.shade300, fontSize: 15, height: 1.6),
                  children: [
                    TextSpan(text: s.tr('contactAgentPart')),
                    TextSpan(
                        text: ' ${s.tr('guest')}',
                        style: const TextStyle(
                            color: AppColors.orange, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    Navigator.pop(context);
                    s.loginAsGuest();
                  },
                  child: Text(s.tr('continueAsGuest'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.tr('cancel'),
                    style: TextStyle(color: Colors.grey.shade400)),
              ),
            ]),
          ),
        ),
      );

  Future<void> _openAdmin() async {
    final s = context.read<AppSettings>();
    var token = await GitHubAdmin.getToken();
    if (token == null || token.isEmpty) {
      token = await askTokenDialog(context, s);
      if (token == null || token.isEmpty) return;
      await GitHubAdmin.saveToken(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.tr('tokenSaved'))));
    }
    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => AdminScreen(token: token!)));
  }
}
