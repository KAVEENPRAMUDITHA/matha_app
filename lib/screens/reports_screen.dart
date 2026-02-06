import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final ImagePicker _picker = ImagePicker();
  final ReportService _reportService = ReportService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        const SnackBar(content: Text("වාර්තාව ඇතුළත් වෙමින් පවතී...")),
      );

      try {
        // ඔබගේ ReportService එක හරහා Firestore වෙත දත්ත යැවීම
        await _reportService.uploadReport(file, "නව ස්කෑන් වාර්තාව");
        messenger.showSnackBar(
          const SnackBar(content: Text("වාර්තාව සාර්ථකව ඇතුළත් කළා!")),
        );
      } catch (e) {
        messenger.showSnackBar(
          const SnackBar(content: Text("දෝෂයකි: ඇතුළත් කිරීම අසාර්ථකයි.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text(
          "වෛද්‍ය වාර්තා",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kCardColor,
        elevation: 0,
      ),
      body: _uid == null
          ? const Center(child: Text("කරුණාකර නැවත ලොග් වන්න."))
          : StreamBuilder<QuerySnapshot>(
              // Firestore හි mothers/{uid}/reports එකතුවෙන් දත්ත ලබා ගැනීම
              stream: FirebaseFirestore.instance
                  .collection('mothers')
                  .doc(_uid)
                  .collection('reports')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryBlue),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "තවමත් වාර්තා ඇතුළත් කර නොමැත.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var report = snapshot.data!.docs[index];
                    DateTime date =
                        (report['uploadedAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    return _buildReportCard(
                      context,
                      report['title'] ?? "වාර්තාව",
                      DateFormat('yyyy-MM-dd HH:mm').format(date),
                      Icons.description,
                      report['imageUrl'] ?? "",
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadImage(context),
        backgroundColor: kPrimaryPink,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String date,
    IconData icon,
    String url,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(icon, color: kPrimaryBlue),
                )
              : Icon(icon, color: kPrimaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(date, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.open_in_new, size: 20, color: kPrimaryPink),
        onTap: () {
          // පින්තූරය විශාල කර පෙන්වීම
          if (url.isNotEmpty) {
            _showImageDialog(context, url);
          }
        },
      ),
    );
  }

  // --- පින්තූරය විශාල කර පෙන්වන Dialog එක ---
  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
