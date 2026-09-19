import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> triggerSOS(String midwifeName, String? emergencyPhone) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Check Location Service and Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? position;
      if (serviceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always)) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      }

      // 2. Get Mother Profile Details for Context
      String motherName = "Mother";
      String motherPhone = "";
      String mohArea = "";
      try {
        final snap = await _db
            .collection('mothers')
            .where('nic', whereIn: [
              FirebaseAuth.instance.currentUser?.email?.split('@').first,
              FirebaseAuth.instance.currentUser?.email?.split('@').first.toUpperCase(),
              FirebaseAuth.instance.currentUser?.email?.split('@').first.toLowerCase(),
            ])
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          motherName = data['fullName'] ?? "Mother";
          motherPhone = data['phone'] ?? "";
          mohArea = data['mohArea'] ?? "";
        }
      } catch (_) {}

      // 3. Save Emergency Alert with Exact GPS to Firestore
      await _db.collection('emergencies').add({
        'motherId': uid,
        'motherName': motherName,
        'motherPhone': motherPhone,
        'mohArea': mohArea,
        'midwifeName': midwifeName,
        'location': position != null
            ? GeoPoint(position.latitude, position.longitude)
            : null,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'googleMapsUrl': position != null
            ? "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}"
            : null,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      // 4. Dial Emergency Phone (if provided)
      if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
        final Uri launchUri = Uri(scheme: 'tel', path: emergencyPhone);
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}