// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';


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
              icon: const Icon(PhosphorIconsRegular.user),
              tooltip: AppLocalizations.of(context).profileTooltip,
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
              icon: const Icon(PhosphorIconsRegular.signOut),
              tooltip: AppLocalizations.of(context).logoutLabel,
              onPressed: () async {
                final l10n = AppLocalizations.of(context);
                final shouldLogout = await showAppDialog(
                  context,
                  title: l10n.logoutTitle,
                  message: l10n.logoutConfirmation,
                  confirmText: l10n.logoutLabel,
                  icon: PhosphorIconsRegular.signOut,
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
