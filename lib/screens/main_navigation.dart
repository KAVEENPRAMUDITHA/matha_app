import 'package:flutter/material.dart';
import '../widgets/matha_background.dart';
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

  final List<Widget> _screens = [
    const HomeScreen(),
    ReportsScreen(),
    const ClinicScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // තිරයේ ප්‍රමාණය අනුව උස සහ පෑඩිං තීරණය කිරීම
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      extendBody: true, // Navigation එක පසුබිම මත පාවීමට ඉඩ ලබාදේ
      body: MathaBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildPremiumNavBar(bottomPadding),
    );
  }

  Widget _buildPremiumNavBar(double bottomPadding) {
    return Container(
      // පතුලේ ඇති safe area එක සමඟ උස සකස් කිරීම
      margin: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        // ඉහළ ඉර ඉවත් කිරීමට shadow එක මෘදු කිරීම
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 75,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, "මුල් පිටුව", 0),
              _buildNavItem(Icons.auto_graph_rounded, "වාර්තා", 1),
              _buildNavItem(Icons.calendar_month_rounded, "සායනය", 2),
              _buildNavItem(Icons.face_retouching_natural_rounded, "ගිණුම", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color primaryColor = const Color(0xFFF06292);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.all(isSelected ? 10 : 8),
              decoration: BoxDecoration(
                // Shadow Error එක වළක්වා ගැනීමට ස්ථාවර Shadow එකක් සහ වර්ණය පමණක් වෙනස් කිරීම
                color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.blueGrey.shade200,
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 4),
            // Text Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? primaryColor : Colors.blueGrey.shade200,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}