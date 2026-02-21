import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _kAppVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (enabled) {
      await FirebaseMessaging.instance.requestPermission();
    } else {
      await FirebaseMessaging.instance.deleteToken();
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

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://example.com/privacy'; // Replace with real URL
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
        backgroundColor: TaskTheme.background,
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
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: TaskTheme.body),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_left_rounded,
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
            color: iconColor.withOpacity(0.1),
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
          activeColor: TaskTheme.primary,
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
