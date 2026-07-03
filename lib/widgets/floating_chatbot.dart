import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ===================================================================
//  Floating Chatbot — Sarah · Midwife Assistant
//
//  Architecture:
//    • FloatingChatbot  → just the 3-D pulsing FAB overlay
//    • _ChatbotPage     → full-screen page (slide-up) with WebView
//
//  Full-screen avoids the cramped-panel + double-header problems:
//    ✓ Keyboard space handled automatically by Scaffold
//    ✓ No competing header (Gradio's own header hidden via JS/CSS)
//    ✓ Users can type and scroll freely
// ===================================================================

// ──────────────────────────────────────────────────────────────────
//  Floating 3-D Pulsing FAB
// ──────────────────────────────────────────────────────────────────
class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot>
    with TickerProviderStateMixin {
  // Pulse glow
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Orbit ring spin
  late final AnimationController _orbitController;
  late final Animation<double> _orbitAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _orbitAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_orbitController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _openChat() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const _ChatbotPage(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 420),
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
            right: 20,
            bottom: 160, // sits above the bottom nav bar
            child: _build3DFAB(),
          ),
        ],
      ),
    );
  }

  Widget _build3DFAB() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _orbitAnim]),
      builder: (_, __) {
        final pulse = _pulseAnim.value;
        final orbit = _orbitAnim.value;

        return GestureDetector(
          onTap: _openChat,
          child: SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 68 + pulse * 14,
                  height: 68 + pulse * 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFAA44FF,
                        ).withValues(alpha: 0.35 * pulse),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFFFF4488,
                        ).withValues(alpha: 0.25 * pulse),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

                // Orbit ring
                Transform.rotate(
                  angle: orbit,
                  child: CustomPaint(
                    size: const Size(68, 68),
                    painter: _OrbitRingPainter(),
                  ),
                ),

                // Main sphere
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      radius: 0.85,
                      colors: [Color(0xFF9C6FE0), Color(0xFF4A148C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7E57C2).withValues(alpha: 0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glass highlight
                      Positioned(
                        top: 8,
                        left: 10,
                        child: Container(
                          width: 16,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const Text('🫀', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Full-Screen Chatbot Page
// ──────────────────────────────────────────────────────────────────
class _ChatbotPage extends StatefulWidget {
  const _ChatbotPage();

  @override
  State<_ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<_ChatbotPage> {
  late final WebViewController _webController;
  bool _ready = false;

  static const _botUrl = 'https://wgkpramuditha-maternal-health-bot.hf.space';

  /// JavaScript injected after page load to:
  ///   1. Hide Gradio's redundant app title / description
  ///   2. Hide the built-with footer
  ///   3. Remove share / flag buttons clutter
  static const _hideRedundancyJs = r'''
    (function() {
      var style = document.createElement('style');
      style.textContent = `
        /* Hide Gradio title block */
        .main-header,
        .app-header,
        .gradio-container .prose h1,
        .gradio-container .prose h2,
        .gradio-container .prose p:first-of-type,
        div.prose { display: none !important; }

        /* Hide share / flag / like buttons */
        .share-button,
        button[title="Flag"],
        button[aria-label="Flag"],
        .footer-wrap,
        .built-with,
        footer { display: none !important; }

        /* Remove top padding left by hidden title */
        .gradio-container { padding-top: 0 !important; }
        .contain { padding-top: 4px !important; }

        /* Ensure chat input is always at bottom */
        .chatbot { min-height: 0 !important; }
      `;
      document.head.appendChild(style);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1035))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // Inject CSS to hide Gradio's redundant UI
            await _webController.runJavaScript(_hideRedundancyJs);
            if (mounted) setState(() => _ready = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(_botUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold automatically resizes for keyboard
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────
          _buildHeader(context),

          // ── WebView — fills all remaining space ──────────────────
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webController),
                if (!_ready) _buildLoader(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFFD44060)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Center(
                  child: Text('👩‍⚕️', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),

              // Name & status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sarah',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69FF47),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Midwife Assistant · Online now',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Container(
      color: const Color(0xFF1A1035),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFFE040FB),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sarah is waking up…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Custom Painter — spinning orbit ring around the FAB
// ──────────────────────────────────────────────────────────────────
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rx = size.width / 2 + 2;
    final ry = size.height * 0.22;

    final paint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      paint,
    );

    final dotPaint = Paint()..color = const Color(0xFFE040FB);
    canvas.drawCircle(Offset(center.dx + rx, center.dy), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
