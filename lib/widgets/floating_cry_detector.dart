import 'dart:math';
import 'package:flutter/material.dart';
import '../screens/baby_cry_analyzer_screen.dart';

// ===================================================================
//  Floating Cry Detector — 3D Pulsing Audio FAB Overlay
//
//  Features:
//    • Concentric acoustic sound-wave pulse animation
//    • Rotating audio frequency ring with particle dots
//    • 3D Glossy Sphere with baby emoji + acoustic waveform icon
//    • "Cry AI" mini badge / tooltip
//    • Silky smooth slide-up navigation to BabyCryAnalyzerScreen
// ===================================================================

class FloatingCryDetector extends StatefulWidget {
  final double bottom;
  final double right;

  const FloatingCryDetector({
    super.key,
    this.bottom = 180,
    this.right = 20,
  });

  @override
  State<FloatingCryDetector> createState() => _FloatingCryDetectorState();
}

class _FloatingCryDetectorState extends State<FloatingCryDetector>
    with TickerProviderStateMixin {
  // Acoustic sound-wave pulse
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Sound wave ring spin
  late final AnimationController _waveController;
  late final Animation<double> _waveAnim;

  // Interactive scale on tap
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_waveController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _openCryAnalyzer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black26,
        pageBuilder: (_, __, ___) => const BabyCryAnalyzerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SizedBox.expand so the positioned FAB has a full-screen reference frame
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            right: widget.right,
            bottom: widget.bottom,
            child: _build3DFAB(),
          ),
        ],
      ),
    );
  }

  Widget _build3DFAB() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _waveAnim]),
      builder: (_, __) {
        final pulse = _pulseAnim.value;
        final wave = _waveAnim.value;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _openCryAnalyzer();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer Glow & Acoustic Waves
                  Container(
                    width: 68 + pulse * 14,
                    height: 68 + pulse * 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.32 * pulse),
                          blurRadius: 26,
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.35 * pulse),
                          blurRadius: 22,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  // Rotating Sound-Wave Frequency Ring
                  Transform.rotate(
                    angle: -wave,
                    child: CustomPaint(
                      size: const Size(68, 68),
                      painter: _AudioWaveRingPainter(),
                    ),
                  ),

                  // Main 3D Sphere Orb
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.35, -0.4),
                        radius: 0.88,
                        colors: [
                          Color(0xFFFF80AB), // Soft Radiant Pink / Coral
                          Color(0xFFE91E63), // Vibrant Deep Rose
                          Color(0xFF880E4F), // Deep Velvet Magenta
                        ],
                        stops: [0.0, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.6),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFF00B0FF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(-2, -3),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glass Highlight Pill
                        Positioned(
                          top: 8,
                          left: 10,
                          child: Container(
                            width: 16,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        // Center Icons: Baby with mini sound ripple
                        const Center(
                          child: Text(
                            '👶',
                            style: TextStyle(fontSize: 26),
                          ),
                        ),

                        // Mini Audio Wave / Mic Badge in corner
                        Positioned(
                          bottom: 5,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.graphic_eq_rounded,
                              size: 11,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Mini Tooltip Badge: "Cry AI"
                  Positioned(
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hearing_rounded,
                            color: Color(0xFF00363A),
                            size: 9,
                          ),
                          SizedBox(width: 3),
                          Text(
                            "Cry AI",
                            style: TextStyle(
                              color: Color(0xFF00363A),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Custom Painter — Sound wave frequency orbit ring around the FAB
// ──────────────────────────────────────────────────────────────────
class _AudioWaveRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rx = size.width / 2 + 2;
    final ry = size.height * 0.24;

    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      paint,
    );

    // Cyan glowing satellite node
    final dotPaint = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawCircle(Offset(center.dx - rx, center.dy), 4, dotPaint);

    // Pink secondary satellite node
    final dotPaintPink = Paint()..color = const Color(0xFFFF4081);
    canvas.drawCircle(Offset(center.dx + rx, center.dy), 3, dotPaintPink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
