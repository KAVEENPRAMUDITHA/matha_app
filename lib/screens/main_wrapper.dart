import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/matha_background.dart'; // අපේ පසුබිම
import 'login_screen.dart';
import 'main_navigation.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            // බලා සිටින විට පවා ලස්සන පසුබිමක් පෙන්වීමට
            body: MathaBackground(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF06292),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}