import 'package:flutter/material.dart';
import 'package:park_janana/services/auth_service.dart';

class UserHeader extends StatelessWidget implements PreferredSizeWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Image.asset(
        'assets/images/park_logo.png',
        height: 50.0, // Adjust the size of the logo
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
                      leading: const Icon(Icons.logout),
                      title: const Text('התנתק'),
                      onTap: () async {
                        await AuthService().signOut();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
