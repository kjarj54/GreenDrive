import 'package:flutter/material.dart';
import 'package:greendrive/widgets/home/feedsection.dart';
import 'package:greendrive/widgets/home/mapsection.dart';
import 'package:greendrive/widgets/home/profilesection.dart';

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
    const ProfileSection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sections[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
