// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/main.dart' show navigatorKey;

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('התנתקות', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'האם אתה בטוח שברצונך להתנתק?',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('ביטול', style: TextStyle(fontSize: 16)),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('התנתק', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
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
                      color: Colors.black.withOpacity(0.08),
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
              count: notificationBadgeCount,
              onTap: onNotificationTap,
            ),

            // Overflow menu (settings + logout)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF374151),
                size: 22,
              ),
              tooltip: 'אפשרויות',
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              onSelected: (v) async {
                if (v == 'settings') onSettingsTap();
                if (v == 'logout') await _logout(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded,
                            size: 19, color: Color(0xFF374151)),
                        SizedBox(width: 10),
                        Text('הגדרות',
                            style: TextStyle(color: Color(0xFF111827))),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 19),
                        SizedBox(width: 10),
                        Text('התנתקות',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widget: notification bell ─────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF374151),
            size: 24,
          ),
          tooltip: 'התראות',
          onPressed: onTap,
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
  }
}
