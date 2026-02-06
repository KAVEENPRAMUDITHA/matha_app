import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaathaApp());
}

class MaathaApp extends StatelessWidget {
  const MaathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maatha App',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.pink),
      home: const SplashScreen(), // දැන් මෙය සාර්ථකව වැඩ කරනු ඇත
    );
  }
}
