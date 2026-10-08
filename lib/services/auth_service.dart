import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Static cryptographic pepper injected into the hashing entropy pool
  static const String _pepper = "Maatha#Secret#2026";

  /// Computes SHA-256 digest: Hash(Password + Dynamic Salt + Static Pepper)
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt + _pepper);
    return sha256.convert(bytes).toString();
  }

  /// Authenticates mother via NIC and password without transmitting plain text
  Future<User?> signIn(String nic, String password) async {
    try {
      // 1. Fetch the user's specific cryptographic salt from Firestore
      var snapshot = await _db
          .collection('mothers')
          .where('nic', isEqualTo: nic.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("User not found in Firestore");
        return null;
      }

      // Retrieve the salt for the specific user
      String salt = snapshot.docs.first.get('salt');

      // 2. Hash the input password with the retrieved salt and static pepper
      String hashedInputPassword = _hashPassword(password.trim(), salt);

      // 4. Email Masking
      String maskedEmail = "${nic.trim().toLowerCase()}@maatha.lk";

      // 5. Authenticate with Firebase using the masked email and hashed password
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