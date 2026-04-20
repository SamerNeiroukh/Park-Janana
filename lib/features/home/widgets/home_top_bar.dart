// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/main.dart' show navigatorKey;
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Minimal RTL top bar for the Home Screen.
///
/// Layout (RTL — right edge → left edge):
///   [🔔 badge] [⋯ menu]  |  [Park Logo]  |  [avatar]
class HomeTopBar extends StatelessWidget {
  final String profilePictureUrl;
  final int notificationBadgeCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  const HomeTopBar({
    super.key,
    required this.profilePictureUrl,
    required this.notificationBadgeCount,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showAppDialog(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutConfirmation,
      confirmText: l10n.logoutLabel,
      icon: PhosphorIconsRegular.signOut,
      isDestructive: true,
    );

    if (ok != true) return;

    try {
      await AuthService().signOut();
    } catch (_) {}

    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── START (right in RTL): avatar ────────────────────────────
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ProfileAvatar(
                  imageUrl: profilePictureUrl,
                  radius: 22,
                ),
              ),
            ),

            // ── CENTER: park logo ────────────────────────────────────────
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/park_logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ── END (left in RTL): action buttons ────────────────────────

            // Notification bell with optional badge
            _NotificationBell(
              notificationBadgeCount: notificationBadgeCount,
              onTap: onNotificationTap,
            ),

            // Overflow menu (settings + logout)
            PopupMenuButton<String>(
              icon: const Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                color: Color(0xFF374151),
                size: 22,
              ),
              tooltip: AppLocalizations.of(context).optionsTooltip,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              onSelected: (v) async {
                if (v == 'settings') onSettingsTap();
                if (v == 'logout') await _logout(context);
              },
              itemBuilder: (ctx) {
                final l10n = AppLocalizations.of(ctx);
                return [
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.gear,
                            size: 19, color: Color(0xFF374151)),
                        const SizedBox(width: 10),
                        Text(l10n.settingsMenu,
                            style: const TextStyle(color: Color(0xFF111827))),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.signOut, color: Colors.red, size: 19),
                        const SizedBox(width: 10),
                        Text(l10n.logoutLabel,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      );
  }
}

// ── Private sub-widget: notification bell ─────────────────────────────────

class _NotificationBell extends StatefulWidget {
  // notificationBadgeCount kept for API compatibility but ignored —
  // the real unread count is streamed from Firestore below.
  final int notificationBadgeCount;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.notificationBadgeCount,
    required this.onTap,
  });

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  Stream<QuerySnapshot>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null) {
      final uid = context.read<AppAuthProvider>().uid;
      _stream = uid == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                PhosphorIconsRegular.bell,
                color: Color(0xFF374151),
                size: 24,
              ),
              tooltip: AppLocalizations.of(context).notificationsTooltip,
              onPressed: widget.onTap,
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
