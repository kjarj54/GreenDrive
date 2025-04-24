import 'package:flutter/material.dart';
import 'package:greendrive/providers/user_provider.dart';
import 'package:greendrive/screens/login_screen.dart';
import 'package:greendrive/screens/vehicle_registration_screen.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:provider/provider.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final name = userProvider.name ?? 'Unknown';
    final email = userProvider.email ?? 'No email';

    return Column(
      children: [
        const SizedBox(height: 48),
        const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(email),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children:
                ListTile.divideTiles(
                  context: context,
                  tiles: [
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: const Text('Register Vehicle'),
                      onTap: () {
                        final userId = userProvider.userId;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VehicleRegistrationScreen(
                                  usuarioId: userId ?? 0,
                                ),
                          ),
                        );
                      },
                    ),
                    const ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.history),
                      title: Text('History'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.help),
                      title: Text('Help'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () async {
                        await AuthService().logout();
                        userProvider.clearUser();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ).toList(),
          ),
        ),
      ],
    );
  }
}
