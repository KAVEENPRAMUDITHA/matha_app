import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase Auth පද්ධතියේ වෙනස්කම් නිරීක්ෂණය කිරීම
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // දත්ත ලැබෙන තෙක් බලා සිටීම
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // පරිශීලකයා ලොග් වී ඇත්නම් Main Navigation එක පෙන්වීම
        if (snapshot.hasData) {
          return const MainNavigation();
        }

        // පරිශීලකයා ලොග් වී නොමැති නම් Login Screen එක පෙන්වීම
        return const LoginScreen();
      },
    );
  }
}