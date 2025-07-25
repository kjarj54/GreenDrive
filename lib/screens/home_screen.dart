import 'package:flutter/material.dart';
import 'package:greendrive/widgets/home/calculatorsection.dart';
import 'package:greendrive/widgets/home/feedsection.dart';
import 'package:greendrive/widgets/home/mapsection.dart';
import 'package:greendrive/widgets/home/profilesection.dart';
import 'package:greendrive/widgets/home/testsectionnotification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _sections = [
    const MapSection(),
    const FeedSection(),
    const CalculatorSection(),
    const ProfileSection(),
    const NotificationTestScreen(),
  ];

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
            },
          ),
        ],
      ),
      body: _sections[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculdora'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
        ],
      ),
    );
  }
}
