import 'dart:math';
import 'package:flutter/material.dart';

class MathaBackground extends StatefulWidget {
  final Widget child;

  const MathaBackground({super.key, required this.child});

  @override
  State<MathaBackground> createState() => _MathaBackgroundState();
}

class _MathaBackgroundState extends State<MathaBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // ඉතාමත් සිනිඳු ඇනිමේෂන් එකක් සඳහා තත්පර 25ක කාලයක්
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Soft Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF0F3), // මෘදු රෝස
                  Color(0xFFF8F0FF), // මෘදු ලැවෙන්ඩර්
                  Color(0xFFEDF7FF), // මෘදු නිල්
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. පසුබිමේ ඇති මෘදු Glowing Orbs (සන්සුන් බව සඳහා)
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowingOrb(350, const Color(0xFFFFD1DC).withOpacity(0.4)),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _buildGlowingOrb(300, const Color(0xFFBBDEFB).withOpacity(0.3)),
          ),

          // 3. ඇනිමේට් වන අයිකන (Floating & Rotating Icons)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // මෙහි අයිකන වල ප්‍රමාණය (Size) සහ පිහිටීම ලස්සනට සකසා ඇත
                  _buildEnhancedIcon(Icons.child_care_rounded, 0.1, 0.15, 85, 0.5),
                  _buildEnhancedIcon(Icons.favorite_rounded, 0.8, 0.1, 70, -0.3),
                  _buildEnhancedIcon(Icons.auto_awesome_rounded, 0.05, 0.75, 55, 0.8),
                  _buildEnhancedIcon(Icons.bedroom_baby_rounded, 0.45, 0.8, 95, 0.2),
                  _buildEnhancedIcon(Icons.cloud_rounded, 0.65, 0.65, 120, -0.1),
                  _buildEnhancedIcon(Icons.toys_rounded, 0.88, 0.75, 80, 1.2),
                  _buildEnhancedIcon(Icons.stars_rounded, 0.25, 0.05, 75, -0.5),
                  _buildEnhancedIcon(Icons.stroller_rounded, 0.35, 0.5, 50, 0.4),
                ],
              );
            },
          ),

          // 4. ඉදිරියෙන් දිස්වන Content එක
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  // පසුබිම් ආලෝක ගෝල සාදන Method එක
  Widget _buildGlowingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 40,
          )
        ],
      ),
    );
  }

  // පාවෙන සහ කැරකෙන අයිකන සාදන Method එක (මෙය කලින් කේතයේ මගහැරී තිබුණි)
  Widget _buildEnhancedIcon(IconData icon, double top, double left, double size, double initialRotation) {
    // සිනිඳු චලනයන් සඳහා සූත්‍ර
    double verticalShift = sin(_controller.value * 2 * pi) * 25;
    double horizontalShift = cos(_controller.value * 2 * pi) * 15;
    double rotation = initialRotation + (sin(_controller.value * 2 * pi) * 0.2);

    return Positioned(
      top: MediaQuery.of(context).size.height * top + verticalShift,
      left: MediaQuery.of(context).size.width * left + horizontalShift,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: 0.12, // ඉතාමත් මෘදු ලෙස දිස්වීමට
          child: Icon(
            icon,
            size: size,
            color: const Color(0xFFF06292).withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}