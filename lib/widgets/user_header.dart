// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:park_janana/services/auth_service.dart';
import '../constants/app_constants.dart';
import '../screens/settings/notification_settings_screen.dart';

class UserHeader extends StatelessWidget implements PreferredSizeWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Padding(
        padding: const EdgeInsets.only(bottom: 10.0), // ✅ Added padding below the logo
        child: Image.asset(
          AppConstants.parkLogo,
          height: 50.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('הגדרות התראות'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('התנתק'),
                      onTap: () async {
                        await AuthService().signOut();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
