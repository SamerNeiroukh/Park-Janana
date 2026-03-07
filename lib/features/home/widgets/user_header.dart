// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';


class UserHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showLogoutButton;
  final VoidCallback? onProfileTap;
  const UserHeader({super.key, this.showLogoutButton = false, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: onProfileTap != null
          ? IconButton(
              icon: const Icon(Icons.person_rounded),
              tooltip: 'פרופיל',
              onPressed: onProfileTap,
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Image.asset(
          AppConstants.parkLogo,
          height: 50.0,
        ),
      ),
      actions: showLogoutButton
          ? [
              IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתקות',
              onPressed: () async {
                final shouldLogout = await showAppDialog(
                  context,
                  title: 'התנתקות',
                  message: 'האם אתה בטוח שברצונך להתנתק?',
                  confirmText: 'התנתק',
                  icon: Icons.logout_rounded,
                  isDestructive: true,
                );
                if (shouldLogout ?? false) {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  }
                }
              },
            ),
          ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
