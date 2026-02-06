import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nicController = TextEditingController();
  final _passController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: kPrimaryPink, size: 100),
              const SizedBox(height: 15),
              const Text(
                "මාතා",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),

              // NIC ඇතුළත් කරන කොටස
              TextField(
                controller: _nicController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "NIC Number",
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.badge, color: kPrimaryBlue),
                  filled: true,
                  fillColor: kCardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // මුරපදය ඇතුළත් කරන කොටස
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.lock, color: kPrimaryBlue),
                  filled: true,
                  fillColor: kCardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // පිවිසෙන බොත්තම
              _isLoading
                  ? const CircularProgressIndicator(color: kPrimaryPink)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        if (_nicController.text.isNotEmpty &&
                            _passController.text.isNotEmpty) {
                          setState(() => _isLoading = true);

                          // AuthService හරහා login වීම
                          var user = await _auth.signIn(
                            _nicController.text,
                            _passController.text,
                          );

                          setState(() => _isLoading = false);

                          if (user != null) {
                            // සාර්ථක නම් Dashboard එකට යන්න (මෙහි Dashboard එකේ නම ඇතුළත් කරන්න)
                            // Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "පිවිසීම අසාර්ථකයි. NIC හෝ මුරපදය වැරදියි.",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "කරුණාකර සියලු විස්තර ඇතුළත් කරන්න.",
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
