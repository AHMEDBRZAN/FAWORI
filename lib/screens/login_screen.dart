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
                      _pill(Icons.nightlightButton.styleFrom(f_round, AppColors.orange,
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
            Icon(ic, color: c, size:oregroundColor: AppColors.teal), 20),
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
                Transform.scale(scale: 
              ),
1 + _pulse.value * 0.03, child: child),
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
                     ),
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
 ],
        ),            ),
         
      );

 ],
        ),  Widget _footer
      );

(AppSettings s)  Widget _footer => Center(
(AppSettings s)        child: Row => Center(
(
          main        child: RowAxisSize: MainAxisSize(
          main.min,
         AxisSize: MainAxisSize children: [
.min,
                     Text(s.tr children: [
('noAccount'),            Text(s.tr style: TextStyle(color('noAccount'),: Colors style: TextStyle(color.grey.shade4: Colors00)),
.grey.shade4            const SizedBox(width00)),
: 6),            const SizedBox(width
            GestureDetector(: 6),
            GestureDetector(
              onTap: () => _account
              onTap: () => _accountDialog(s),
              child: TextDialog(s),
              child: Text(s.tr('signUp'),
                 (s.tr('sign style: constUp'),
                  TextStyle(
                      style: const TextStyle(
                      color: AppColors.orange, fontWeight: color: AppColors FontWeight.w80.orange, fontWeight:0)),
            FontWeight.w800)),
            ),
          ],
        ),
 ),
          ],      );

 
        ),
 Widget _accountType      );

 (AppSettings s) Widget _accountType => Container(
(AppSettings s)        height:  => Container(
58,
        height:         padding: const58,
 EdgeInsets.symmetric(horizontal:        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: 14), BoxDecoration(
         
        decoration: borderRadius: BorderRadius.circular BoxDecoration(
         (16), borderRadius: BorderRadius.circular
          border:(16), Border.all(color:
          border: Colors.grey.shade Border.all(color:700), Colors.grey.shade700),
        ),
        child: Dropdown
        ),
ButtonHideUnderline        child: Dropdown(
          childButtonHideUnderline: DropdownButton<String(
          child>(
            is: DropdownButton<StringExpanded: true,>(
            is
            dropdownColorExpanded: true,
            dropdownColor: Theme.of(context).colorScheme.surface: Theme.of(context,
            value).colorScheme.surface: _type,,
            value
            hint:: _type, Text(s.tr('
            hint:accountType'),
                style: TextStyle Text(s.tr('accountType'),
(color: Colors.grey                style: TextStyle(color: Colors.grey.shade40.shade400)),
            items: ['agent0)),
           ', 'tech', items: ['agent 'guest']
', 'tech',                .map(( 'guest']
t) => Dropdown                .map((MenuItem(value: tt) => Dropdown, child: TextMenuItem(value: t(s.tr(t)))), child: Text(s.tr(t))))
                .toList(),
            onChanged
                .toList: (v)(),
            onChanged => setState(() =>: (v) _type = v => setState(() =>),
          ), _type = v
        ),
),
          ),      );

 
        ),
 Widget _field(App      );

 Settings s, TextEditingController Widget _field(AppSettings s, TextEditingController c, String hintKey, IconData ic,
 c, String hintKey, IconData          {TextInputType ic,
? keyboard, int          {TextInputType? maxLength, bool? keyboard, int obscure = false,? maxLength, bool Widget? suffix}) obscure = false, =>
      TextField Widget? suffix})(
        controller =>
      TextField: c(
        controller,
        keyboardType: c: keyboard,
        keyboardType,
        maxLength: keyboard: maxLength,
,
        maxLength: maxLength,
        obscureText: obscure,
               obscureText: onChanged: (_) => obscure,
        setState(() {}), onChanged: (_) =>
        decoration: setState(() {}), InputDecoration(
         
        decoration: hintText: s.tr InputDecoration(
         (hintKey), hintText: s.tr(hintKey),
          prefixIcon: Icon(ic,
          prefixIcon: Icon(ic, color: Colors.white70),
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder color: Colors.white70),
          suffixIcon: suffix,
         (
              borderRadius enabledBorder: OutlineInputBorder: BorderRadius.circular((
              borderRadius16),
: BorderRadius.circular(              borderSide: BorderSide16),
(color: Colors.grey              borderSide: BorderSide.shade70(color: Colors.grey0)),
         .shade700)),
          focusedBorder: OutlineInputBorder(
              borderRadius focusedBorder: OutlineInputBorder: BorderRadius.circular((
              borderRadius16),
: BorderRadius.circular(              borderSide: const16),
 BorderSide(color: App              borderSide: constColors.teal, BorderSide(color: App width: 2Colors.teal, width: 2)),
          counterStyle: TextStyle(color)),
          counter: Colors.grey.shStyle: TextStyle(colorade500: Colors.grey.shade500, fontSize: 12),
, fontSize: 12),
        ),
      );

  void        ),
      _accountDialog(App );

  voidSettings s) => _accountDialog(AppSettings s) => showDialog(
        context: context, showDialog(
       
        builder: context: context, (_) => Dialog(
        builder:
          backgroundColor: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding Colors.transparent,
          child: Container: const EdgeInsets.all(
            padding: const EdgeInsets.all(24),
            decoration:(24),
            decoration: BoxDecoration(
              color: Theme.of BoxDecoration(
             (context).colorScheme.surface,
              color: Theme.of(context).colorScheme borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withAlpha(70)),
            ),.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withAlpha(70
            child:)),
            ), Column(mainAxisSize:
            child: MainAxisSize.min, Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
 children: [
                width:               Container(
70, height                width: : 7070, height,
                decoration: 70: BoxDecoration(
,
                decoration                  shape: Box: BoxDecoration(
Shape.circle,
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                  gradient: LinearGradient                    AppColors.orange(colors: [
.withAlpha(1                    AppColors.orange20),
.withAlpha(1                    AppColors.te20),
al.withAlpha(                    AppColors.te80)
al.withAlpha(                  ]),
80)
                  ]),
                ),
                child: const Icon                ),
               (Icons.support_agent_round child: const Iconed,
(Icons.support_agent_round                    color: Colorsed,
.white, size:                    color: Colors 34),.white, size:
              ),
 34),              const SizedBox(height: 16
              ),
              const SizedBox(height),
              Text: 16(s.tr('create),
              TextAccount'),
                 (s.tr('create style: const TextStyleAccount'),
                 (fontSize: 2 style: const TextStyle0, fontWeight:(fontSize: 2 FontWeight.w800, fontWeight:0)),
              FontWeight.w800)),
              const SizedBox(height: 10), const SizedBox(height:
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      color 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle: Colors.grey.sh(
                      colorade300: Colors.grey.sh, fontSize: ade30015, height, fontSize: : 1.15, height6),
                 : 1. children: [
6),
                                     TextSpan(text children: [
: s.tr('                    TextSpan(textcontactAgentPart')),: s.tr('contactAgentPart')),
                    TextSpan(
                        text
                    TextSpan: ' ${s(
                        text.tr('guest'): ' ${s}',
                        style.tr('guest'): const TextStyle(}',
                        style
                            color:: const TextStyle( AppColors.orange,
                            color: fontWeight: FontWeight.w AppColors.orange,800)), fontWeight: FontWeight.w
                  ],
800)),                ),
             
                  ],
 ),
              const                ),
              ),
              const SizedBox(height: 22),
 SizedBox(height:               SizedBox(
22),
                width: double              SizedBox(
.infinity,
                               width: double height: 5.infinity,
               2,
                height: 5 child: ElevatedButton2,
               (
                  child: ElevatedButton style: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: App.styleFrom(
Colors.orange,
                      backgroundColor: App                      foregroundColor:Colors.orange,
 Colors.black,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius                      shape: RoundedRectangleBorder: BorderRadius.circular((
                          borderRadius16))),
: BorderRadius.circular(                  onPressed: ()16))),
 {
                    Navigator                  onPressed: ().pop(context);
 {
                    Navigator.pop(context);
                    s.loginAsGuest();
                                     s.loginAs },
                  childGuest();
                 : Text(s.tr },
                  child('continueAsGuest: Text(s.tr'),
                      style('continueAsGuest: const TextStyle(font'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),Weight: FontWeight.w
                ),
800)),              ),
             
                ),
 const SizedBox(height:              ),
              8),
 const SizedBox(height:              TextButton( 8),

                onPressed:              TextButton( () => Navigator.pop
                onPressed:(context),
                () => Navigator.pop child: Text(s(context),
               .tr('cancel'), child: Text(s
                    style:.tr('cancel'), TextStyle(color: Colors
                    style:.grey.shade4 TextStyle(color: Colors.grey.shade400)),
              ),
           00)),
 ]),
                       ),
            ),
        ]),
          ),
      ); ),
       

  Future<void ),
      );> _openAdmin

  Future<void() async {
> _openAdmin    final s =() async {
 context.read<AppSettings    final s =>();
    var context.read<AppSettings token = await GitHub>();
    var token = await GitHubAdmin.getToken();
    if (tokenAdmin.getToken();
 == null || token    if (token.isEmpty) {
 == null || token      token = await.isEmpty) {
 askTokenDialog(context      token = await, s);
 askTokenDialog(context      if (token, s);
      if (token == null || token.isEmpty) return; == null || token.isEmpty) return;
      await GitHubAdmin.saveToken(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .show
      await GitHubAdmin.saveToken(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(sSnackBar(SnackBar.tr('tokenSaved(content: Text(s'))));
   .tr('tokenSaved }
    if'))));
    (!mounted) return }
    if;
    Navigator (!mounted) return.push(
       ;
    Navigator context, MaterialPageRoute(builder.push(
       : (_) => Admin context, MaterialPageRoute(builderScreen(token: token: (_) => Admin!)));
 Screen(token: token }
}
!)));
  }
}
