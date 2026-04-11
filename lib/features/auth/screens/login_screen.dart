import 'dart:async';
import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_strings.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/features/home/screens/home_screen.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/auth/screens/forgot_password_screen.dart';
import 'package:park_janana/core/services/biometric_service.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _kHeroBg = Colors.white;
const _kBlobBlue = Color(0xFFD6EEFA);   // soft sky-blue blob
const _kBlobYellow = Color(0xFFFFF0C2); // soft warm-yellow blob
const _kBlobRed = Color(0xFFFFE0E0);    // soft coral/red blob
const _kCardBg = Color(0xFFF8FAFC);     // barely-off-white card
const _kBtnStart = Color(0xFF1A8FD1);   // gradient button deep
const _kBtnEnd = Color(0xFF56C2F4);     // gradient button light
const _kHeroHeight = 0.33; // fraction of screen height

// ── Banner type ──────────────────────────────────────────────────────────────
enum _BannerType { error, warning, success }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricLoginEnabled = false;

  String? _emailError;
  String? _passwordError;

  // ── Inline banner state ───────────────────────────────────────────────────
  String? _bannerMessage;
  _BannerType _bannerType = _BannerType.error;
  Timer? _bannerTimer;

  void _showBanner(String message, _BannerType type) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = message;
      _bannerType = type;
    });
    _bannerTimer = Timer(const Duration(seconds: 5), _dismissBanner);
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerMessage = null);
  }

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isAvailable();
    final enabled = await _biometricService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricLoginEnabled = enabled;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        if (!mounted) return;
        _showBanner('אימות ביומטרי נכשל. אנא נסה שוב.', _BannerType.error);
        return;
      }

      final creds = await _biometricService.getCredentials();
      if (creds == null) {
        if (!mounted) return;
        _showBanner(
          'לא נמצאו פרטי כניסה שמורים. אנא כנס עם אימייל וסיסמה.',
          _BannerType.warning,
        );
        setState(() => _biometricLoginEnabled = false);
        return;
      }

      await _authService.signIn(creds.email, creds.password);
      if (!mounted) return;
      _navigateToHomeScreen();
    } on CustomException catch (e) {
      if (!mounted) return;
      _showBanner(e.message, _BannerType.error);
    } catch (e) {
      if (!mounted) return;
      _showBanner('שגיאה: $e', _BannerType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _offerBiometricSetup(String email, String password) async {
    if (!mounted) return;
    final enable = await showAppDialog(
      context,
      title: 'כניסה ביומטרית',
      message: 'האם לאפשר כניסה עתידית באמצעות טביעת אצבע / זיהוי פנים?',
      confirmText: 'אפשר',
      cancelText: 'לא, תודה',
      icon: PhosphorIconsRegular.fingerprint,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
    );
    if (enable ?? false) {
      await _biometricService.saveCredentials(email, password);
    }
  }

  Future<void> _login() async {
    _dismissBanner();
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await _authService.signIn(email, password);

      if (_biometricAvailable && !_biometricLoginEnabled) {
        await _offerBiometricSetup(email, password);
      }

      if (!mounted) return;
      _navigateToHomeScreen();
    } on CustomException catch (e) {
      if (!mounted) return;

      final errorMsg = e.message;

      if (errorMsg.startsWith('ACCOUNT_REJECTED:')) {
        final uid = errorMsg.substring('ACCOUNT_REJECTED:'.length);
        _showRejectedDialog(uid);
        return;
      }

      setState(() {
        if (errorMsg.contains('האימייל לא נמצא במערכת') ||
            errorMsg.contains('כתובת האימייל לא תקינה')) {
          _emailError = errorMsg;
        } else if (errorMsg.contains('הסיסמה שגויה')) {
          _passwordError = errorMsg;
        } else {
          _showBanner(
            errorMsg,
            errorMsg.contains('לא אושר') ? _BannerType.warning : _BannerType.error,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showBanner('שגיאה: $e', _BannerType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectedDialog(String uid) {
    showAppDialog(
      context,
      title: 'הבקשה נדחתה',
      message: 'בקשתך לאישור נדחתה על ידי ההנהלה.\nניתן לשלוח בקשת אישור חדשה.',
      confirmText: 'שלח בקשה מחדש',
      cancelText: 'ביטול',
      icon: PhosphorIconsRegular.xCircle,
      iconGradient: const [Color(0xFFFF8C00), Color(0xFFE65100)],
    ).then((confirmed) async {
      if (confirmed ?? false) {
        await _reApply(uid);
      } else {
        await _authService.signOut();
      }
    });
  }

  Future<void> _reApply(String uid) async {
    setState(() => _isLoading = true);
    try {
      await _authService.reApply(uid);
      if (!mounted) return;
      _showBanner(
        'הבקשה נשלחה מחדש. ההנהלה תעדכן אותך בהחלטה.',
        _BannerType.success,
      );
    } on CustomException catch (e) {
      if (!mounted) return;
      _showBanner(e.message, _BannerType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHomeScreen() {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kHeroBg,
        body: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────────────────
            SizedBox(
              height: size.height * _kHeroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // White background
                  const ColoredBox(color: _kHeroBg),

                  // Blob — large, top-right (sky blue)
                  Positioned(
                    top: -55,
                    right: -55,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBlobBlue,
                      ),
                    ),
                  ),

                  // Blob — medium, bottom-left (warm yellow)
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBlobYellow,
                      ),
                    ),
                  ),

                  // Blob — small, top-left (soft coral)
                  Positioned(
                    top: topPad + 30,
                    left: 60,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBlobRed,
                      ),
                    ),
                  ),

                  // Park logo — centered
                  Center(
                    child: Image.asset(
                      AppConstants.parkLogo,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Back button — top left, light style for white bg
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.arrowRight,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content card ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          const Text(
                            'שלום, ברוכים הבאים',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'אנא הכנס את פרטי הכניסה שלך',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // ── Inline banner ─────────────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: _bannerMessage != null
                                ? _StatusBanner(
                                    message: _bannerMessage!,
                                    type: _bannerType,
                                    onDismiss: _dismissBanner,
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // ── Email field ───────────────────────────────────
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textAlign: TextAlign.right,
                            decoration: _inputDecoration(
                              label: 'אימייל',
                              hint: 'הכנס את כתובת האימייל שלך',
                              icon: PhosphorIconsRegular.envelope,
                              errorText: _emailError,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'אנא הכנס כתובת אימייל';
                              }
                              if (!value.contains('@')) {
                                return 'אנא הכנס כתובת אימייל תקינה';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Password field ────────────────────────────────
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            textAlign: TextAlign.right,
                            decoration: _inputDecoration(
                              label: 'סיסמה',
                              hint: 'הכנס את הסיסמה שלך',
                              icon: PhosphorIconsRegular.lock,
                              errorText: _passwordError,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? PhosphorIconsRegular.eye
                                      : PhosphorIconsRegular.eyeSlash,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'אנא הכנס סיסמה';
                              }
                              if (value.length < 6) {
                                return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // ── Forgot password ───────────────────────────────
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: const Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Login button (gradient) ───────────────────────
                          _GradientButton(
                            onPressed: _isLoading ? null : _login,
                            isLoading: _isLoading,
                            label: 'כניסה',
                          ),

                          // ── Biometric ─────────────────────────────────────
                          if (_biometricAvailable && _biometricLoginEnabled) ...[
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'או',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed:
                                    _isLoading ? null : _loginWithBiometrics,
                                icon: const Icon(PhosphorIconsRegular.fingerprint,
                                    color: AppColors.primary, size: 22),
                                label: const Text(
                                  'כניסה ביומטרית',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shared input decoration factory
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      floatingLabelStyle:
          const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      errorText: errorText,
      errorStyle:
          const TextStyle(color: AppColors.error, fontSize: 12, height: 1.3),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}

// ── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String message;
  final _BannerType type;
  final VoidCallback onDismiss;

  const _StatusBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  Color get _bg => switch (type) {
        _BannerType.error => const Color(0xFFFFEBEE),
        _BannerType.warning => const Color(0xFFFFF8E1),
        _BannerType.success => const Color(0xFFE8F5E9),
      };

  Color get _fg => switch (type) {
        _BannerType.error => const Color(0xFFD32F2F),
        _BannerType.warning => const Color(0xFFE65100),
        _BannerType.success => const Color(0xFF2E7D32),
      };

  Color get _border => switch (type) {
        _BannerType.error => const Color(0xFFEF9A9A),
        _BannerType.warning => const Color(0xFFFFCC80),
        _BannerType.success => const Color(0xFFA5D6A7),
      };

  IconData get _icon => switch (type) {
        _BannerType.error => PhosphorIconsRegular.warningCircle,
        _BannerType.warning => PhosphorIconsRegular.warning,
        _BannerType.success => PhosphorIconsRegular.checkCircle,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(_icon, color: _fg, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: _fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(top: 1, right: 2),
                child: Icon(
                  PhosphorIconsRegular.x,
                  color: _fg.withValues(alpha: 0.55),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient login button ─────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? const LinearGradient(
                colors: [Color(0xFFB0BEC5), Color(0xFFB0BEC5)],
              )
            : const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [_kBtnStart, _kBtnEnd],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? []
            : const [
                BoxShadow(
                  color: Color(0x591A8FD1),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
