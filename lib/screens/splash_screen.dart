import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // තත්පර 3කට පසු MainWrapper වෙත මාරු වීම
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ලෝගෝව පෙන්වීම
            Image.asset('assets/maathalogo.png', width: 220, height: 220),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: kPrimaryPink),
          ],
        ),
      ),
    );
  }
}
