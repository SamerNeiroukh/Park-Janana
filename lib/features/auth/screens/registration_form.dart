import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/features/auth/screens/welcome_screen.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kYellow = Color(0xFFF6C34C);
const _kAmber = Color(0xFFD97706);
const _kBg = Color(0xFFF9FAFB);
const _kGreen = Color(0xFF22C55E);
const _kRed = Color(0xFFEF4444);

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _idFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _submitted = false;
  bool _passVisible = false;
  bool _confirmVisible = false;

  final Map<String, String?> _errors = {
    'name': null, 'phone': null, 'id': null,
    'email': null, 'pass': null, 'confirm': null,
  };
  final Set<String> _touched = {};

  AnimationController? _successCtrl;
  Animation<double>? _successScale;

  static final _hebrewRx = RegExp(r'^[א-ת\s]+$');
  static final _phoneRx = RegExp(r'^\d{10}$');
  static final _idRx = RegExp(r'^\d{9}$');
  static final _emailRx = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static bool _isValidIsraeliId(String id) {
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      int step = int.parse(id[i]) * (i % 2 == 0 ? 1 : 2);
      if (step > 9) step -= 9;
      sum += step;
    }
    return sum % 10 == 0;
  }

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl!,
      curve: Curves.elasticOut,
    );

    void blurListener(FocusNode node, String key) {
      node.addListener(() {
        if (!mounted) return;
        if (!node.hasFocus) _validateField(key);
      });
    }

    blurListener(_nameFocus, 'name');
    blurListener(_phoneFocus, 'phone');
    blurListener(_idFocus, 'id');
    blurListener(_emailFocus, 'email');
    blurListener(_passFocus, 'pass');
    blurListener(_confirmFocus, 'confirm');
  }

  @override
  void dispose() {
    _successCtrl?.dispose();
    for (final c in [
      _nameCtrl, _phoneCtrl, _idCtrl,
      _emailCtrl, _passCtrl, _confirmCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus, _phoneFocus, _idFocus,
      _emailFocus, _passFocus, _confirmFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  void _validateField(String key) {
    if (!mounted) return;
    setState(() {
      _touched.add(key);
      _errors[key] = _getError(key);
    });
  }

  String? _getError(String key) {
    switch (key) {
      case 'name':
        final v = _nameCtrl.text.trim();
        if (v.isEmpty) return 'יש להזין שם מלא';
        if (!_hebrewRx.hasMatch(v)) return 'יש להזין שם בעברית בלבד';
        return null;
      case 'phone':
        final phone = _phoneCtrl.text.trim();
        if (!_phoneRx.hasMatch(phone)) {
          return 'מספר טלפון חייב להכיל בדיוק 10 ספרות';
        }
        if (!phone.startsWith('05')) {
          return 'מספר טלפון ישראלי חייב להתחיל ב-05';
        }
        return null;
      case 'id':
        final id = _idCtrl.text.trim();
        if (!_idRx.hasMatch(id)) {
          return 'תעודת זהות חייבת להכיל בדיוק 9 ספרות';
        }
        if (!_isValidIsraeliId(id)) {
          return 'מספר תעודת הזהות אינו תקין';
        }
        return null;
      case 'email':
        if (!_emailRx.hasMatch(_emailCtrl.text.trim())) {
          return 'כתובת אימייל אינה תקינה';
        }
        return null;
      case 'pass':
        if (_passCtrl.text.length < 6) {
          return 'הסיסמה חייבת להכיל לפחות 6 תווים';
        }
        return null;
      case 'confirm':
        if (_confirmCtrl.text != _passCtrl.text) return 'הסיסמאות אינן תואמות';
        return null;
      default:
        return null;
    }
  }

  bool _validateAll() {
    for (final key in ['name', 'phone', 'id', 'email', 'pass', 'confirm']) {
      _touched.add(key);
      _errors[key] = _getError(key);
    }
    return _errors.values.every((e) => e == null);
  }

  int get _errorCount => _errors.values.where((e) => e != null).length;

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_validateAll()) {
      setState(() {});
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.createUser(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        _nameCtrl.text.trim(),
        _idCtrl.text.trim(),
        _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
      _successCtrl?.forward();
    } on CustomException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
          for (final entry in e.fieldErrors!.entries) {
            _errors[entry.key] = entry.value;
            _touched.add(entry.key);
          }
        } else {
          // Fallback for single-message errors (e.g. Firebase Auth)
          final String field;
          if (e.message.contains('טלפון')) {
            field = 'phone';
          } else if (e.message.contains('זהות')) {
            field = 'id';
          } else {
            field = 'email';
          }
          _errors[field] = e.message;
          _touched.add(field);
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: _submitted ? _buildSuccess() : _buildForm(context),
      ),
    );
  }

  // ── Success view ─────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _successScale ?? const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _kGreen, size: 64),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'הבקשה נשלחה בהצלחה!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'הנהלת הפארק תבדוק את פרטיך ותיצור איתך קשר בהקדם האפשרי.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kYellow.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: _kAmber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'לאחר אישור ההנהלה תקבל גישה לאפליקציה ותוכל להתחבר.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _kAmber,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kYellow,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                },
                child: const Text(
                  'חזור לדף הראשי',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form view ────────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final hasErrors = _touched.isNotEmpty && _errorCount > 0;

    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: _kYellow.withValues(alpha: 0.4), width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: _kAmber.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
              top: topPad + 4, bottom: 14, left: 8, right: 16),
          child: Row(
            children: [
              // Park logo — first child = RIGHT in RTL
              Image.asset(
                AppConstants.parkLogo,
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'הרשמה לפארק גננה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'מלא את הפרטים לשליחת בקשת הצטרפות',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Back button — last child = LEFT in RTL
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                color: _kAmber,
                splashRadius: 24,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // ── Error banner ─────────────────────────────────────────────────────
        if (hasErrors)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: _kRed.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: _kRed, size: 18),
                const SizedBox(width: 8),
                Text(
                  'יש לתקן $_errorCount ${_errorCount == 1 ? 'שגיאה' : 'שגיאות'} לפני שליחה',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kRed,
                  ),
                ),
              ],
            ),
          ),

        // ── Scrollable form ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal details section
                  _sectionHeader(Icons.badge_outlined, 'פרטים אישיים'),
                  const SizedBox(height: 12),
                  _field(
                    key: 'name',
                    ctrl: _nameCtrl,
                    focus: _nameFocus,
                    nextFocus: _phoneFocus,
                    label: 'שם מלא',
                    hint: 'לדוגמה: ישראל ישראלי',
                    icon: Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.name],
                  ),
                  _field(
                    key: 'phone',
                    ctrl: _phoneCtrl,
                    focus: _phoneFocus,
                    nextFocus: _idFocus,
                    label: 'מספר טלפון',
                    hint: '05XXXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    formatters: [IlLocalPhoneFormatter()],
                    autofillHints: const [
                      AutofillHints.telephoneNumber,
                      AutofillHints.telephoneNumberNational,
                    ],
                  ),
                  _field(
                    key: 'id',
                    ctrl: _idCtrl,
                    focus: _idFocus,
                    nextFocus: _emailFocus,
                    label: 'תעודת זהות',
                    hint: '9 ספרות',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                  ),

                  const SizedBox(height: 8),
                  _sectionHeader(Icons.lock_outline_rounded, 'פרטי כניסה'),
                  const SizedBox(height: 12),
                  _field(
                    key: 'email',
                    ctrl: _emailCtrl,
                    focus: _emailFocus,
                    nextFocus: _passFocus,
                    label: 'כתובת אימייל',
                    hint: 'name@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  _field(
                    key: 'pass',
                    ctrl: _passCtrl,
                    focus: _passFocus,
                    nextFocus: _confirmFocus,
                    label: 'סיסמה',
                    hint: 'לפחות 6 תווים',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_passVisible,
                    showToggle: true,
                    toggleVisible: _passVisible,
                    onToggle: () => setState(() => _passVisible = !_passVisible),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  _field(
                    key: 'confirm',
                    ctrl: _confirmCtrl,
                    focus: _confirmFocus,
                    label: 'אישור סיסמה',
                    hint: 'הזן שוב את הסיסמה',
                    icon: Icons.lock_reset_outlined,
                    obscure: !_confirmVisible,
                    showToggle: true,
                    toggleVisible: _confirmVisible,
                    onToggle: () =>
                        setState(() => _confirmVisible = !_confirmVisible),
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _submit,
                    autofillHints: const [AutofillHints.newPassword],
                  ),

                  const SizedBox(height: 8),

                  // Info notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _kYellow.withValues(alpha: 0.4), width: 1),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFFB45309), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'לאחר שליחת הבקשה, ההנהלה תאשר את חשבונך ותוכל להתחבר לאפליקציה.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF92400E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _kAmber))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kYellow,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _submit,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'שלח בקשת הצטרפות',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section header ───────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kAmber),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kAmber,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  // ── Field widget ─────────────────────────────────────────────────────────────

  Widget _field({
    required String key,
    required TextEditingController ctrl,
    required FocusNode focus,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool showToggle = false,
    bool toggleVisible = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    List<String>? autofillHints,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    final isTouched = _touched.contains(key);
    final error = isTouched ? _errors[key] : null;
    final isValid = isTouched && _errors[key] == null;
    final hasError = error != null;

    final borderColor = hasError
        ? _kRed
        : isValid
            ? _kGreen
            : const Color(0xFFD1D5DB);

    final fillColor = hasError
        ? const Color(0xFFFEF2F2)
        : isValid
            ? const Color(0xFFF0FDF4)
            : Colors.white;

    Widget? suffix;
    if (showToggle) {
      suffix = IconButton(
        icon: Icon(
          toggleVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey.shade500,
          size: 20,
        ),
        onPressed: onToggle,
        splashRadius: 20,
      );
    } else if (isValid) {
      suffix = const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
      );
    } else if (hasError) {
      suffix = const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.cancel_rounded, color: _kRed, size: 20),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: hasError ? _kRed : const Color(0xFF6B7280)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasError ? _kRed : const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isValid || hasError
                  ? [
                      BoxShadow(
                        color: (hasError ? _kRed : _kGreen)
                            .withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              obscureText: obscure,
              keyboardType: keyboardType,
              inputFormatters: formatters,
              autofillHints: autofillHints,
              textAlign: TextAlign.right,
              textInputAction:
                  textInputAction ?? TextInputAction.next,
              onEditingComplete: () {
                _validateField(key);
                if (onEditingComplete != null) {
                  onEditingComplete();
                } else if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: fillColor,
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _kRed : _kAmber,
                    width: 2,
                  ),
                ),
                errorText: error,
                errorStyle: const TextStyle(
                  fontSize: 12,
                  color: _kRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone formatter ───────────────────────────────────────────────────────────

class IlLocalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String t = newValue.text
        .replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    if (t.startsWith('972')) t = '0${t.substring(3)}';
    if (t.length == 9 && !t.startsWith('0')) t = '0$t';

    t = t.replaceAll(RegExp(r'\D'), '');
    if (t.length > 10) t = t.substring(0, 10);

    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
