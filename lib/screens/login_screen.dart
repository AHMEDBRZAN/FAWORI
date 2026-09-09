import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../widgets/pressable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _scroll = ScrollController();
  bool _obscure = true;
  String? _type;
  String _statusMessage = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showStatus(String msg, {bool isError = false}) {
    setState(() {
      _statusMessage = msg;
      _isError = isError;
    });
  }

  Future<void> _doLogin(AppSettings s) async {
    // ضيف
    if (_type == 'guest') {
      s.loginAsGuest();
      return;
    }

    // إنشاء حساب جديد
    if (_type == 'create') {
      if (_phone.text.trim().isEmpty || _pass.text.isEmpty) {
        _showStatus('أدخل رقم الهاتف وكلمة المرور', isError: true);
        return;
      }
      _showStatus('لإنشاء حساب جديد، يرجى التواصل مع الوكيل المعتمد\nأو تواصل عباس حسين لفتة ', isError: true);
      return;
    }

    // تسجيل دخول عادي
    final users = await StoreService.loadUsers();
    User? found;
    for (final u in users) {
      if (u.phone == _phone.text.trim()) {
        found = u;
        break;
      }
    }
    if (!mounted) return;
    if (found != null && found.password == _pass.text) {
      s.loginAsUser(found);
    } else {
      _showStatus('رقم الهاتف أو كلمة المرور غير صحيحة', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        body: Stack(
          children: [
            _gradientBackground(),
            _glow(const Color(0xFF3EC6C0), Alignment.topLeft),
            _glow(const Color(0xFFE8A33D), Alignment.bottomRight),
            SafeArea(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _pill(
                          Icons.language_rounded,
                          AppColors.teal,
                          s.isArabic ? 'English' : 'العربية',
                          () => s.toggleLanguage(),
                        ),
                        const SizedBox(width: 10),
                        _pill(
                          Icons.nightlight_round,
                          AppColors.orange,
                          s.tr('darkMode'),
                          () => s.toggleDark(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    _logo(s),
                    const SizedBox(height: 36),
                    _card(s),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isError
                              ? Colors.red.withAlpha(30)
                              : Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isError
                                ? Colors.red.withAlpha(100)
                                : Colors.green.withAlpha(100),
                          ),
                        ),
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isError
                                ? Colors.red.shade300
                                : Colors.green.shade300,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _footer(s),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBackground() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF141419),
              Color(0xFF1A1A1F),
            ],
          ),
        ),
      );

  Widget _glow(Color c, Alignment a) => Positioned.fill(
        child: Align(
          alignment: a,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [c.withAlpha(60), c.withAlpha(0)],
              ),
            ),
          ),
        ),
      );

  Widget _pill(IconData ic, Color c, String label, VoidCallback onTap) =>
      Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.withAlpha(40),
                c.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withAlpha(90)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ic, color: c, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _logo(AppSettings s) => Center(
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: AppColors.orange.withAlpha(110),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withAlpha(70),
                    blurRadius: 45,
                  ),
                ],
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 122,
                    height: 122,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [AppColors.orange, AppColors.teal],
              ).createShader(r),
              child: Text(
                s.tr('appName'),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.tr('appNameSub'),
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );

  Widget _card(AppSettings s) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B21),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.orange.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withAlpha(30),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _accountType(s),
            if (_type != 'guest') ...[
              const SizedBox(height: 14),
              _field(
                s,
                _phone,
                'phoneNumber',
                Icons.person_rounded,
                keyboard: TextInputType.phone,
                maxLength: 11,
              ),
              const SizedBox(height: 14),
              _field(
                s,
                _pass,
                'password',
                Icons.lock_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Pressable(
              onTap: () => _doLogin(s),
              scale: 0.97,
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF26B0F), AppColors.orange],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withAlpha(80),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _type == 'create' ? 'إنشاء حساب' : s.tr('login'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _footer(AppSettings s) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.tr('noAccount'),
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(width: 6),
            Pressable(
              onTap: () => _accountDialog(s),
              child: Text(
                s.tr('signUp'),
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _typeIcon(String t, {double size = 22}) {
    IconData ic;
    Color c;
    switch (t) {
      case 'agent':
        ic = Icons.storefront_rounded;
        c = AppColors.orange;
        break;
      case 'tech':
        ic = Icons.format_paint_rounded;
        c = AppColors.teal;
        break;
      case 'create':
        ic = Icons.person_add_alt_1_rounded;
        c = const Color(0xFF4C8DF5);
        break;
      default:
        ic = Icons.person_outline_rounded;
        c = Colors.grey.shade300;
    }
    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [c.withAlpha(60), c.withAlpha(30)],
        ),
      ),
      child: Icon(ic, color: c, size: size),
    );
  }

  Widget _accountType(AppSettings s) => Pressable(
        onTap: () => _openTypePicker(s),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _type != null
                  ? AppColors.orange.withAlpha(140)
                  : Colors.grey.shade700,
            ),
          ),
          child: Row(
            children: [
              if (_type != null) ...[
                _typeIcon(_type!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  _type == null ? s.tr('accountType') : _getRoleLabel(s, _type!),
                  style: TextStyle(
                    color: _type == null ? Colors.grey.shade400 : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.teal,
              ),
            ],
          ),
        ),
      );

  String _getRoleLabel(AppSettings s, String role) {
    switch (role) {
      case 'agent':
        return 'وكيل معتمد';
      case 'tech':
        return 'صباغ';
      case 'guest':
        return 'تصفح بدون حساب';
      case 'create':
        return 'إنشاء حساب جديد';
      default:
        return s.tr(role);
    }
  }

  void _openTypePicker(AppSettings s) => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B21),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withAlpha(70)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.tr('accountType'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                _typeOption(s, 'agent', 'وكيل معتمد', 'للوكلاء الرسميين'),
                const SizedBox(height: 10),
                _typeOption(s, 'tech', 'صباغ', 'لفنيي الصباغة'),
                const SizedBox(height: 10),
                _typeOption(s, 'guest', 'تصفح بدون حساب', 'استكشاف التطبيق'),
                const SizedBox(height: 10),
                _typeOption(s, 'create', 'إنشاء حساب جديد', 'سجّل حسابك الآن'),
              ],
            ),
          ),
        ),
      );

  Widget _typeOption(AppSettings s, String t, String title, String subtitle) {
    final selected = _type == t;
    return Pressable(
      onTap: () {
        setState(() {
          _type = t;
          _statusMessage = '';
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.orange.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.orange : Colors.grey.shade700,
          ),
        ),
        child: Row(
          children: [
            _typeIcon(t),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  Widget _field(
    AppSettings s,
    TextEditingController c,
    String hintKey,
    IconData ic, {
    TextInputType? keyboard,
    int? maxLength,
    bool obscure = false,
    Widget? suffix,
  }) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        maxLength: maxLength,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() => _statusMessage = ''),
        decoration: InputDecoration(
          hintText: s.tr(hintKey),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(ic, color: Colors.white70),
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
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
              color: const Color(0xFF1B1B21),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withAlpha(70)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.orange.withAlpha(120),
                        AppColors.teal.withAlpha(80),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.tr('createAccount'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    children: [
                      TextSpan(text: s.tr('contactAgentPart')),
                      TextSpan(
                        text: ' ${s.tr('guest')}',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Pressable(
                  onTap: () {
                    Navigator.pop(context);
                    s.loginAsGuest();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        s.tr('continueAsGuest'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Pressable(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      s.tr('cancel'),
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
