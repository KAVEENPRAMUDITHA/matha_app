import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // මේ line එක අනිවාර්යයෙන්ම අවශ්‍යයි

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // NIC සහ Password හරහා Masking ක්‍රමය භාවිතයෙන් Login වීම
  Future<User?> signIn(String nic, String password) async {
    try {
      // 1. NIC එක email එකක් ලෙස සකස් කිරීම (Masking)
      String maskedEmail = "${nic.trim().toLowerCase()}@maatha.lk";

      // 2. Firebase Auth හරහා කෙලින්ම ලොග් වීම
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: maskedEmail,
        password: password.trim(),
      );
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      // මෙතැනදී debugPrint වැඩ කිරීමට නම් ඉහත import එක තිබිය යුතුයි
      debugPrint("Login Error: ${e.code}");
      return null;
    } catch (e) {
      debugPrint("General Error: $e");
      return null;
    }
  }

  // Logout වීම
  Future<void> signOut() async => await _auth.signOut();
}