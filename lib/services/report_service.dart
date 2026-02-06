import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // පින්තූරය Upload කිරීමේ ක්‍රියාවලිය
  Future<void> uploadReport(File imageFile, String reportName) async {
    if (_uid == null) return;

    try {
      // 0. NIC එක masked email එකෙන් ලබා ගැනීම
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      String nic = userEmail.split('@').first;

      // 1. මවගේ ලේඛනය NIC හරහා සොයා ගන්න
      QuerySnapshot motherQuery = await _db
          .collection('mothers')
          .where('motherNIC', isEqualTo: nic)
          .limit(1)
          .get();

      if (motherQuery.docs.isEmpty) {
        throw Exception("මවගේ දත්ත සොයාගත නොහැක");
      }

      String motherDocId = motherQuery.docs.first.id;

      // 2. Storage එකේ ගොනුව ගබඩා කරන ස්ථානය නම් කිරීම
      String fileName =
          'reports/$motherDocId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);

      // 3. පින්තූරය Upload කිරීම
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 4. පින්තූරයට අදාළ URL එක ලබා ගැනීම
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 5. Firestore හි මවගේ වාර්තා යටතට දත්ත එක් කිරීම
      await _db.collection('mothers').doc(motherDocId).collection('reports').add({
        'title': reportName,
        'imageUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
