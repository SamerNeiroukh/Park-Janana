import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/screens/welcome_screen.dart';
import 'package:park_janana/features/home/providers/home_badge_provider.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:park_janana/core/services/biometric_service.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';

const _kAppVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
    _loadBiometricState();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true);
    }
  }

  Future<void> _loadBiometricState() async {
    final available = await _biometricService.isAvailable();
    final enabled = await _biometricService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // Ask for current password to securely store credentials
      final result = await _showBiometricEnableSheet();
      if (result != true) return; // user cancelled
    } else {
      await _biometricService.clearCredentials();
      if (mounted) setState(() => _biometricEnabled = false);
    }
  }

  /// Shows a bottom sheet asking for the current password, then authenticates
  /// biometrically and saves credentials if both succeed.
  Future<bool?> _showBiometricEnableSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BiometricEnableSheet(
        biometricService: _biometricService,
        onEnabled: () {
          if (mounted) setState(() => _biometricEnabled = true);
        },
      ),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    final messaging = FirebaseMessaging.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (enabled) {
      try {
        final settings = await messaging.requestPermission();
        final authorized = settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        if (authorized && uid != null) {
          final token = await messaging.getToken();
          if (token != null) {
            await FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .doc(uid)
                .update({'fcmTokens': FieldValue.arrayUnion([token])});
          }
        }
      } catch (e) {
        debugPrint('FCM enable notifications skipped: $e');
      }
    } else {
      try {
        final token = await messaging.getToken();
        await messaging.deleteToken();
        if (token != null && uid != null) {
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .update({'fcmTokens': FieldValue.arrayRemove([token])});
        }
      } catch (e) {
        debugPrint('FCM disable notifications skipped: $e');
      }
    }

    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showAppDialog(
      context,
      title: 'התנתקות',
      message: 'האם אתה בטוח שברצונך להתנתק?',
      confirmText: 'התנתק',
      icon: Icons.logout_rounded,
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    try {
      // Delete FCM token so device stops receiving push notifications
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    if (!mounted) return;

    // Clear all user state before signing out to prevent stale data
    context.read<UserProvider>().clearUser();
    context.read<HomeBadgeProvider>().reset();
    await context.read<AppAuthProvider>().signOut();

    // Navigate to welcome screen — prevents stale HomeScreen state from
    // being reused if the same device is handed to a different user.
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://park-janana.co.il/privacy';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח את הקישור')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('הגדרות', style: TaskTheme.heading2),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _sectionHeader('חשבון'),
                  _tile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: TaskTheme.inProgress,
                    title: 'שינוי סיסמה',
                    onTap: _showChangePasswordSheet,
                  ),
                  if (_biometricAvailable)
                    _switchTile(
                      icon: Icons.fingerprint_rounded,
                      iconColor: TaskTheme.done,
                      title: 'כניסה ביומטרית',
                      subtitle: 'טביעת אצבע / זיהוי פנים',
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  const SizedBox(height: 20),
                  _sectionHeader('התראות'),
                  _switchTile(
                    icon: Icons.notifications_outlined,
                    iconColor: TaskTheme.primary,
                    title: 'התראות פוש',
                    subtitle: 'קבלת עדכונים על משמרות ומשימות',
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),
                  const SizedBox(height: 20),
                  _sectionHeader('מידע'),
                  _tile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: TaskTheme.done,
                    title: 'מדיניות פרטיות',
                    trailing: const Icon(Icons.open_in_new_rounded,
                        size: 16, color: TaskTheme.textTertiary),
                    onTap: _openPrivacyPolicy,
                  ),
                  _tile(
                    icon: Icons.info_outline_rounded,
                    iconColor: TaskTheme.textSecondary,
                    title: 'גרסת האפליקציה',
                    trailing: Text(
                      _kAppVersion,
                      style:
                          TaskTheme.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                    onTap: null,
                  ),
                  const SizedBox(height: 20),
                  _sectionHeader('יציאה'),
                  _tile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red.shade600,
                    title: 'התנתקות',
                    titleColor: Colors.red.shade700,
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TaskTheme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: TaskTheme.primary,
              fontSize: 12,
              letterSpacing: 0.5)),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        boxShadow: TaskTheme.softShadow,
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: TaskTheme.body.copyWith(color: titleColor)),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: TaskTheme.textTertiary)
                : null),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        boxShadow: TaskTheme.softShadow,
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: TaskTheme.body),
        subtitle: subtitle != null
            ? Text(subtitle, style: TaskTheme.caption)
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: TaskTheme.primary,
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser!
          .updatePassword(_newPasswordController.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הסיסמה עודכנה בהצלחה')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'requires-recent-login'
            ? 'יש להתחבר מחדש לפני שינוי הסיסמה'
            : 'שגיאה בעדכון הסיסמה';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: TaskTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TaskTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('שינוי סיסמה', style: TaskTheme.heading2),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'סיסמה חדשה',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TaskTheme.radiusM)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'נא להזין סיסמה';
                    if (v.trim().length < 6) return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'אימות סיסמה',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TaskTheme.radiusM)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _newPasswordController.text) {
                      return 'הסיסמאות אינן תואמות';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM),
                      gradient: const LinearGradient(
                        colors: [TaskTheme.primary, Color(0xFF5B8DEF)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow:
                          TaskTheme.buttonShadow(TaskTheme.primary),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(TaskTheme.radiusM),
                        onTap: _isLoading ? null : _submit,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  ),
                                )
                              : const Text(
                                  'עדכן סיסמה',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Biometric Enable Sheet
// ---------------------------------------------------------------------------

class _BiometricEnableSheet extends StatefulWidget {
  const _BiometricEnableSheet({
    required this.biometricService,
    required this.onEnabled,
  });

  final BiometricService biometricService;
  final VoidCallback onEnabled;

  @override
  State<_BiometricEnableSheet> createState() => _BiometricEnableSheetState();
}

class _BiometricEnableSheetState extends State<_BiometricEnableSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authenticated = await widget.biometricService.authenticate(
        reason: 'אמת את זהותך כדי להפעיל כניסה ביומטרית',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('האימות הביומטרי נכשל')),
          );
        }
        return;
      }

      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      await widget.biometricService.saveCredentials(
        email,
        _passwordController.text.trim(),
      );

      widget.onEnabled();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בהפעלת הכניסה הביומטרית')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: TaskTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TaskTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('הפעלת כניסה ביומטרית', style: TaskTheme.heading2),
                const SizedBox(height: 8),
                const Text(
                  'הזן את הסיסמה הנוכחית שלך כדי לאפשר כניסה עם טביעת אצבע / זיהוי פנים.',
                  style: TaskTheme.caption,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'סיסמה נוכחית',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TaskTheme.radiusM)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'נא להזין סיסמה';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM),
                      gradient: const LinearGradient(
                        colors: [TaskTheme.primary, Color(0xFF5B8DEF)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow:
                          TaskTheme.buttonShadow(TaskTheme.primary),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(TaskTheme.radiusM),
                        onTap: _isLoading ? null : _submit,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  ),
                                )
                              : const Text(
                                  'הפעל כניסה ביומטרית',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
