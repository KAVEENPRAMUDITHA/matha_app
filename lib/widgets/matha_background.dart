import 'dart:math';
import 'package:flutter/material.dart';

// ===================================================================
//  MAATHA AMBIENT BACKGROUND — Ultra-Smooth Luminous Maternal Canvas
// ===================================================================

class MathaBackground extends StatefulWidget {
  final Widget child;

  const MathaBackground({super.key, required this.child});

  @override
  State<MathaBackground> createState() => _MathaBackgroundState();
}

class _MathaBackgroundState extends State<MathaBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
          // 1. Multi-tone Luxury Pastel Gradient Base
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF1F4), // Ultra soft blush rose
                  Color(0xFFF7F3FF), // Silky lavender mist
                  Color(0xFFEFF8FF), // Serene celestial sky
                  Color(0xFFF5FFFA), // Refreshing soft mint
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Animated Floating Bokeh Glow Orbs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value * 2 * pi;
              final shiftX1 = cos(t) * 35;
              final shiftY1 = sin(t) * 25;
              final shiftX2 = -sin(t) * 30;
              final shiftY2 = cos(t) * 25;

              return Stack(
                children: [
                  // Top-Right Rose-Pink Glow
                  Positioned(
                    top: -60 + shiftY1,
                    right: -50 + shiftX1,
                    child: _buildGlowingOrb(
                      340,
                      const Color(0xFFFF80AB).withValues(alpha: 0.28),
                    ),
                  ),

                  // Bottom-Left Sky-Cyan Glow
                  Positioned(
                    bottom: -60 + shiftY2,
                    left: -50 + shiftX2,
                    child: _buildGlowingOrb(
                      320,
                      const Color(0xFF00E5FF).withValues(alpha: 0.20),
                    ),
                  ),

                  // Center-Right Lavender Glow
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.45 + shiftY1 * 0.5,
                    right: -70 + shiftX2 * 0.5,
                    child: _buildGlowingOrb(
                      260,
                      const Color(0xFFB388FF).withValues(alpha: 0.22),
                    ),
                  ),

                  // Floating Ambient Maternal Icons
                  _buildFloatingIcon(Icons.child_care_rounded, 0.12, 0.10, 50, 0.3),
                  _buildFloatingIcon(Icons.favorite_rounded, 0.78, 0.08, 44, -0.4),
                  _buildFloatingIcon(Icons.auto_awesome_rounded, 0.06, 0.78, 38, 0.6),
                  _buildFloatingIcon(Icons.stars_rounded, 0.42, 0.85, 48, -0.2),
                  _buildFloatingIcon(Icons.cloud_rounded, 0.68, 0.72, 60, 0.1),
                  _buildFloatingIcon(Icons.spa_rounded, 0.28, 0.05, 42, 0.4),
                ],
              );
            },
          ),

          // 3. Foreground Safe Content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildGlowingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 110,
            spreadRadius: 45,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(
    IconData icon,
    double topRatio,
    double leftRatio,
    double size,
    double initialRotation,
  ) {
    final t = _controller.value * 2 * pi;
    final verticalShift = sin(t) * 18;
    final horizontalShift = cos(t) * 12;
    final rotation = initialRotation + (sin(t) * 0.15);

    return Positioned(
      top: MediaQuery.of(context).size.height * topRatio + verticalShift,
      left: MediaQuery.of(context).size.width * leftRatio + horizontalShift,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: 0.14,
          child: Icon(
            icon,
            size: size,
            color: const Color(0xFFF06292).withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}