import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class SOSService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // හදිසි පණිවිඩය සහ Location එක යැවීමේ ප්‍රධාන ක්‍රියාවලිය
  Future<void> triggerSOS(String midwifeName) async {
    if (_uid == null) return;

    try {
      // 1. Location අවසර පරීක්ෂා කිරීම
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // 2. මව සිටින ස්ථානය (Latitude & Longitude) ලබා ගැනීම
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Firestore හි 'emergencies' එකතුවට දත්ත එක් කිරීම
      await _db.collection('emergencies').add({
        'motherId': _uid,
        'midwifeName': midwifeName,
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });
    } catch (e) {
      print("SOS Error: $e");
      rethrow;
    }
  }
}