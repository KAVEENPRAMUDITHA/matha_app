import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../widgets/matha_background.dart'; // පසුබිම් විජට් එක import කරන්න

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
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
      duration: const Duration(seconds: 2),
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
        _nicController.text,
        _passController.text,
      );

      if (mounted) setState(() => _isLoading = false);

      if (user != null) {
        // Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorSnackBar("පිවිසීම අසාර්ථකයි. විස්තර නැවත පරීක්ෂා කරන්න.\nLogin Failed. Check your details.");
      }
    } else {
      _showErrorSnackBar("කරුණාකර සියලු විස්තර ඇතුළත් කරන්න.\nPlease fill all details.");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // පාවෙන අයිකන සහිත පසුබිම භාවිතා කිරීම
      body: MathaBackground(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFF06292),
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "මාතා",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1565C0),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    "MAATHA",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 45),

                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "ආයුබෝවන්\nWelcome",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 35),

                        _buildInputField(
                          controller: _nicController,
                          label: "හැඳුනුම්පත් අංකය (NIC)",
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 20),

                        _buildInputField(
                          controller: _passController,
                          label: "මුරපදය (Password)",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 40),

                        _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFF06292))
                            : InkWell(
                                onTap: _loginLogic,
                                child: Container(
                                  width: double.infinity,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF06292), Color(0xFF64B5F6)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "ඇතුල් වන්න / LOGIN",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "© 2026 Maatha Digital Maternal Care",
                    style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: const Color(0xFF64B5F6), size: 26),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFF06292), width: 1.5),
        ),
      ),
    );
  }
}