// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:park_janana/services/auth_service.dart';
import '../constants/app_constants.dart';

class UserHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showLogoutButton;
  const UserHeader({super.key, this.showLogoutButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
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
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children:  [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('התנתקות', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'האם אתה בטוח שברצונך להתנתק?',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        actionsAlignment: MainAxisAlignment.spaceBetween,
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('ביטול', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('התנתק', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
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
