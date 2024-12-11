import 'package:flutter/material.dart';
import 'package:kongkon_app_driver/api/auth_provider.dart';
import 'package:kongkon_app_driver/shared/theme.dart';
import 'package:provider/provider.dart';

class DrawerWidget extends StatelessWidget {
  final AuthProvider? authProvider;
  final String? avatar_file_name;
  final String? name;
  final String? license;
  final String? userId;
  const DrawerWidget(
      {Key? key,
      this.avatar_file_name,
      this.name,
      this.license,
      this.userId,
      this.authProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF6200EE),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.pushNamed(
                        context, '/profile'); // Navigate to profile
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        'http://192.168.1.35:3333/uploads/avatars/${avatar_file_name}'), // Placeholder for profile image
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${name}', // Replace with dynamic name
                  style: whiteTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: semibold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${license}', // Replace with dynamic email
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(
              'Wallet',
              style:
                  blackTextStyle.copyWith(fontSize: 18, fontWeight: semibold),
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              if (userId != null) {
                // Pass userId when navigating to wallet
                Navigator.pushNamed(context, '/wallet', arguments: userId);
              } // Navigate to wallet
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(
              'Settings',
              style:
                  blackTextStyle.copyWith(fontSize: 18, fontWeight: semibold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings'); // Navigate to settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'Logout',
              style: blackTextStyle.copyWith(fontSize: 18, fontWeight: medium),
            ),
            onTap: () {
              authProvider!.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
