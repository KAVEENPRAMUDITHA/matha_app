import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'community_chat_service.dart';

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
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {}
      }

      // 2. Get Mother Profile Details for Context
      String motherName = "Mother";
      String motherPhone = "";
      String mohArea = "";
      String profilePic = "assets/avatars/avatar1.png";
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
          profilePic = data['profilePic'] ?? "assets/avatars/avatar1.png";
        }
      } catch (_) {}

      final String mapsUrl = position != null
          ? "https://maps.google.com/?q=${position.latitude},${position.longitude}"
          : "ස්ථානය ලබාගත නොහැක";

      // 3. Save Emergency Record to Firestore 'emergencies' collection
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
        'googleMapsUrl': mapsUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'type': 'GPS_SOS',
      });

      // 4. Send Instant Notification to Midwife App
      await _db.collection('midwife_notifications').add({
        'midwifeName': midwifeName,
        'type': 'EMERGENCY_SOS',
        'title': '🚨 හදිසි SOS ස්ථාන ඇඟවීමක්!',
        'body': '$motherName මව ($mohArea) විසින් හදිසි GPS ස්ථානය යවා ඇත.',
        'motherName': motherName,
        'motherPhone': motherPhone,
        'googleMapsUrl': mapsUrl,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 5. Post SOS message to Midwife Community Circle
      try {
        final String groupId = CommunityChatService.normalizeGroupId(midwifeName);
        await _db
            .collection('community_groups')
            .doc(groupId)
            .collection('messages')
            .add({
          'senderId': uid,
          'senderName': motherName,
          'senderRole': 'mother',
          'senderAvatar': profilePic,
          'pregnancyWeek': null,
          'message': '🚨 [හදිසි SOS ඇඟවීමක්] මට හදිසි ආධාර අවශ්‍යයි!\n📍 මාගේ GPS ස්ථානය: $mapsUrl',
          'tag': 'හදිසි SOS',
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
        });
      } catch (_) {}

      // 6. Open SMS with emergency message and Google Maps location to Emergency Contact
      if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
        final String cleanPhone = emergencyPhone.replaceAll(RegExp(r'[^0-9+]'), '');
        final String smsMessage =
            "🚨 හදිසි අවස්ථාවක්! $motherName හට හදිසි ආධාර අවශ්‍යයි.\n📍 GPS ස්ථානය: $mapsUrl\n(Maatha App)";

        final Uri smsUri = Uri(
          scheme: 'sms',
          path: cleanPhone,
          queryParameters: <String, String>{
            'body': smsMessage,
          },
        );

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}