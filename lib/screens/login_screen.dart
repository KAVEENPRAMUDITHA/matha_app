import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/matha_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _nicController = TextEditingController();
  final _passController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  bool _isObscure = true;

  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nicController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _loginLogic() async {
    if (_nicController.text.isNotEmpty && _passController.text.isNotEmpty) {
      setState(() => _isLoading = true);

      var user = await _auth.signIn(
        _nicController.text.trim(),
        _passController.text,
      );

      if (mounted) setState(() => _isLoading = false);

      if (user == null) {
        _showErrorSnackBar(
          "පිවිසීම අසාර්ථකයි. විස්තර නැවත පරීක්ෂා කරන්න.\nLogin Failed. Check your details.",
        );
      }
    } else {
      _showErrorSnackBar("කරුණාකර සියලු විස්තර ඇතුළත් කරන්න.\nPlease fill all details.");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathaBackground(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo Container
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF06292).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFF06292),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "මාතා • MAATHA",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1565C0),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    "ඩිජිටල් මාතෘ හා ළමා සත්කාරක වේදිකාව",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF06292),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "ආයුබෝවන් • Welcome",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 26),

                        _buildInputField(
                          controller: _nicController,
                          label: "හැඳුනුම්පත් අංකය (NIC)",
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 18),

                        _buildInputField(
                          controller: _passController,
                          label: "මුරපදය (Password)",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),

                        _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFF06292))
                            : InkWell(
                                onTap: _loginLogic,
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  width: double.infinity,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF06292), Color(0xFF64B5F6)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF06292).withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "ඇතුල් වන්න / LOGIN",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    "© 2026 Maatha Maternal & Infant Care",
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black45,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF64B5F6), size: 24),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFF06292), width: 1.5),
        ),
      ),
    );
  }
}