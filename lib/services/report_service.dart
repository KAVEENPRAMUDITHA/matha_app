import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final cloudinary = CloudinaryPublic(
    'dzuzvmxq9',
    'maatha_preset',
    cache: false,
  );

  Future<void> uploadReport(File imageFile, String reportName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String nic = user.email!.split('@').first.trim();

      // 1. Upload to Cloudinary
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'medical_reports/$nic',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      String downloadUrl = response.secureUrl;

      // Mother data retrieval for context
      QuerySnapshot motherQuery = await _db
          .collection('mothers')
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();

      if (motherQuery.docs.isEmpty) throw Exception("Mother data not found");
      
      var motherData = motherQuery.docs.first.data() as Map<String, dynamic>;
      String motherName = motherData['fullName'] ?? "N/A";
      String mohArea = motherData['mohArea'] ?? "N/A";
      String assignedMidwifeName = motherData['assignedMidwife'] ?? "N/A";

      // Midwife data retrieval for contact info
      String midwifePhone = "N/A";
      String midwifeEmail = "N/A";

      QuerySnapshot midwifeQuery = await _db
          .collection('midwives')
          .where('fullName', isEqualTo: assignedMidwifeName)
          .limit(1)
          .get();

      if (midwifeQuery.docs.isNotEmpty) {
        var midwifeData = midwifeQuery.docs.first.data() as Map<String, dynamic>;
        midwifePhone = midwifeData['phone'] ?? "N/A";
        midwifeEmail = midwifeData['email'] ?? "N/A";
      }

      // 4. Add the new medical report to the 'medical_reports' collection
      await _db.collection('medical_reports').add({
        // Report Info
        'title': reportName,
        'imageUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        
        // Mother Info
        'motherNIC': nic,
        'motherName': motherName,
        'mohArea': mohArea,

        // Midwife Info (For easy contact & tracking)
        'midwifeName': assignedMidwifeName,
        'midwifePhone': midwifePhone,
        'midwifeEmail': midwifeEmail,
        
        // Search Tags (Optional - For Midwife search)
        'searchKey': assignedMidwifeName.toLowerCase(),
      });

    } catch (e) {
      print("Error in ReportService: $e");
      rethrow;
    }
  }
}