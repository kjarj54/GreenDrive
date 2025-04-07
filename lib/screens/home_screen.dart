import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GreenDrive'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navegar al perfil del usuario
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badges',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildBadge(context, Icons.ev_station, 'Estaciones'),
                _buildBadge(context, Icons.route, 'Rutas'),
                _buildBadge(context, Icons.group, 'Comunidad'),
                _buildBadge(context, Icons.bar_chart, 'Estadísticas'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green.shade100,
          child: Icon(
            icon,
            size: 30,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
        ),
      ],
    );
  }
}