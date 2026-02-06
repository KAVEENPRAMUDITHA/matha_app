import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'clinic_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // ඇප් එකේ ඇති ප්‍රධාන පිටු ලැයිස්තුව
  final List<Widget> _screens = [
    const HomeScreen(), // මුල් පිටුව
    ReportsScreen(), // වෛද්‍ය වාර්තා පිටුව
    const ClinicScreen(), // සායනික දත්ත
    const ProfileScreen(), // ගිණුම සහ ප්‍රෝෆයිලය
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: kCardColor,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType
            .fixed, // අයිතම 4ක් ඇති බැවින් fixed භාවිතා කිරීම සුදුසුයි
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_rounded),
            label: 'Clinic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
