import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ඇප් එකේ ඇති රහස් අකුරු පෙළ (Registration වලදී භාවිතා කළ එකම විය යුතුය)
  static const String _pepper = "Maatha#Secret#2026";

  // මුරපදය Hash කිරීමේ function එක
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt + _pepper);
    return sha256.convert(bytes).toString();
  }

  Future<User?> signIn(String nic, String password) async {
    try {
      // 1. Firestore එකෙන් මවගේ Salt එක සොයා ගැනීම (NIC එක මඟින්)
      var snapshot = await _db
          .collection('mothers')
          .where('nic', isEqualTo: nic.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("User not found in Firestore");
        return null;
      }

      // 2. දත්ත පද්ධතියෙන් Salt එක ලබා ගැනීම
      String salt = snapshot.docs.first.get('salt');

      // 3. එම Salt සහ Pepper යොදාගෙන ලබාදුන් මුරපදය Hash කිරීම
      String hashedInputPassword = _hashPassword(password.trim(), salt);

      // 4. Email Masking
      String maskedEmail = "${nic.trim().toLowerCase()}@maatha.lk";

      // 5. Firebase Auth හරහා Hash එක මුරපදය ලෙස යොදා ලොග් වීම
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: maskedEmail,
        password: hashedInputPassword,
      );
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.code}");
      return null;
    } catch (e) {
      debugPrint("General Error: $e");
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}