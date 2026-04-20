import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/auth/screens/welcome_screen.dart';
import 'package:park_janana/features/home/providers/home_badge_provider.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:park_janana/core/providers/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:park_janana/core/services/biometric_service.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kAppVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _crashlyticsEnabled = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
    _loadBiometricState();
    _loadCrashlyticsState();
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

  Future<void> _loadCrashlyticsState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _crashlyticsEnabled = prefs.getBool('crashlytics_enabled') ?? true);
    }
  }

  Future<void> _toggleCrashlytics(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('crashlytics_enabled', enabled);
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(enabled);
    if (mounted) setState(() => _crashlyticsEnabled = enabled);
  }

  Future<void> _openTermsOfService() async {
    const url = 'https://samerneiroukh.github.io/janana-privacy/terms.html';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cannotOpenLink)),
        );
      }
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutConfirmation,
      confirmText: l10n.logoutLabel,
      icon: PhosphorIconsRegular.signOut,
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
    const url = 'https://samerneiroukh.github.io/janana-privacy/';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cannotOpenLink)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const UserHeader(),
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
                  child: const Icon(PhosphorIconsRegular.gear,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context).settingsTitle, style: TaskTheme.heading2),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _sectionHeader(l10n.accountSectionHeader),
                    _tile(
                      icon: PhosphorIconsRegular.lock,
                      iconColor: TaskTheme.inProgress,
                      title: l10n.changePasswordTitle,
                      onTap: _showChangePasswordSheet,
                    ),
                    if (_biometricAvailable)
                      _switchTile(
                        icon: PhosphorIconsRegular.fingerprint,
                        iconColor: TaskTheme.done,
                        title: l10n.biometricLoginTitle,
                        subtitle: l10n.biometricMethodsSubtitle,
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                    const SizedBox(height: 20),
                    _sectionHeader(l10n.languageSectionHeader),
                    _buildLanguageTile(context, l10n),
                    const SizedBox(height: 20),
                    _sectionHeader(l10n.notificationsSectionHeader),
                    _switchTile(
                      icon: PhosphorIconsRegular.bell,
                      iconColor: TaskTheme.primary,
                      title: l10n.pushNotificationsTitle,
                      subtitle: l10n.pushNotificationsSubtitle,
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader(l10n.infoSectionHeader),
                    _tile(
                      icon: PhosphorIconsRegular.shieldCheck,
                      iconColor: TaskTheme.done,
                      title: l10n.privacyPolicyTitle,
                      trailing: const Icon(PhosphorIconsRegular.arrowSquareOut,
                          size: 16, color: TaskTheme.textTertiary),
                      onTap: _openPrivacyPolicy,
                    ),
                    _tile(
                      icon: PhosphorIconsRegular.fileText,
                      iconColor: TaskTheme.inProgress,
                      title: l10n.termsOfServiceTitle,
                      trailing: const Icon(PhosphorIconsRegular.arrowSquareOut,
                          size: 16, color: TaskTheme.textTertiary),
                      onTap: _openTermsOfService,
                    ),
                    _switchTile(
                      icon: PhosphorIconsRegular.bug,
                      iconColor: TaskTheme.textSecondary,
                      title: l10n.crashReportsTitle,
                      subtitle: l10n.crashReportsSubtitle,
                      value: _crashlyticsEnabled,
                      onChanged: _toggleCrashlytics,
                    ),
                    _tile(
                      icon: PhosphorIconsRegular.info,
                      iconColor: TaskTheme.textSecondary,
                      title: l10n.appVersionTitle,
                      trailing: Text(
                        _kAppVersion,
                        style: TaskTheme.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                      onTap: null,
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader(l10n.signOutSectionHeader),
                    _tile(
                      icon: PhosphorIconsRegular.signOut,
                      iconColor: Colors.red.shade600,
                      title: l10n.logoutLabel,
                      titleColor: Colors.red.shade700,
                      onTap: _signOut,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _currentLanguageName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'en': return l10n.languageEnglish;
      case 'ar': return l10n.languageArabic;
      default:   return l10n.languageHebrew;
    }
  }

  Widget _buildLanguageTile(BuildContext context, AppLocalizations l10n) {
    final locale = context.watch<LocaleProvider>().locale;
    return _tile(
      icon: PhosphorIconsRegular.globe,
      iconColor: const Color(0xFF7C3AED),
      title: l10n.languageLabel,
      subtitle: _currentLanguageName(locale, l10n),
      trailing: Text(
        _currentLanguageName(locale, l10n),
        style: TaskTheme.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      onTap: () => _showLanguagePicker(context, l10n, locale),
    );
  }

  void _showLanguagePicker(
      BuildContext context, AppLocalizations l10n, Locale current) {
    final options = [
      (const Locale('he'), l10n.languageHebrew,  '🇮🇱'),
      (const Locale('en'), l10n.languageEnglish, '🇬🇧'),
      (const Locale('ar'), l10n.languageArabic,  '🇸🇦'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: TaskTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TaskTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.languageLabel,
                style: TaskTheme.heading2),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final (locale, name, flag) = opt;
              final isSelected = locale.languageCode == current.languageCode;
              return GestureDetector(
                onTap: () {
                  context.read<LocaleProvider>().setLocale(locale);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : TaskTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(name,
                            style: TaskTheme.body.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                  : TaskTheme.textPrimary,
                            )),
                      ),
                      if (isSelected)
                        const Icon(PhosphorIconsFill.checkCircle,
                            color: Color(0xFF7C3AED), size: 20),
                    ],
                  ),
                ),
              );
            }),
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
    String? subtitle,
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
        subtitle: subtitle != null
            ? Text(subtitle,
                style: TaskTheme.caption.copyWith(color: titleColor?.withValues(alpha: 0.7)))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(PhosphorIconsRegular.caretRight,
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
          SnackBar(content: Text(AppLocalizations.of(context).passwordChanged)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final msg = e.code == 'requires-recent-login'
            ? l10n.requiresRecentLoginError
            : l10n.updatePasswordError;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
              Text(l10n.changePasswordTitle, style: TaskTheme.heading2),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.newPasswordLabel,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.passwordRequiredValidator;
                  if (v.trim().length < 6) return l10n.passwordMinLengthValidation;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordLabel,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return l10n.passwordMismatchValidation;
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
                    boxShadow: TaskTheme.buttonShadow(TaskTheme.primary),
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
                            : Text(
                                l10n.updatePasswordButton,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
        reason: AppLocalizations.of(context).biometricVerifyReason,
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).biometricAuthFailedSnackbar)),
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
          SnackBar(content: Text(AppLocalizations.of(context).enableBiometricError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
              Text(l10n.enableBiometricTitle, style: TaskTheme.heading2),
              const SizedBox(height: 8),
              Text(
                l10n.biometricEnableDescription,
                style: TaskTheme.caption,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.currentPasswordLabel,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TaskTheme.radiusM)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.passwordRequiredValidator;
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
                    boxShadow: TaskTheme.buttonShadow(TaskTheme.primary),
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
                            : Text(
                                l10n.activateBiometricButton,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
    );
  }
}

