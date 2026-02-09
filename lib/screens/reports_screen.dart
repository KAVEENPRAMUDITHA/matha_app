import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // දින වකවානු පෙන්වීමට
import '../widgets/matha_background.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ImagePicker _picker = ImagePicker();
  final ReportService _reportService = ReportService();
  bool _isUploading = false;

  // --- වාර්තාවට නමක් දීමේ Dialog එක ---
  Future<void> _pickAndUpload(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    TextEditingController nameController = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Column(
          children: [
            Icon(Icons.edit_document, color: Color(0xFFF06292), size: 40),
            SizedBox(height: 10),
            Text("වාර්තාවේ නම", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
          ],
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "උදා: 3rd Month Scan",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.label_important_rounded, color: Colors.blueAccent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("අවලංගුයි", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF06292),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _startUpload(File(image.path), nameController.text);
              }
            },
            child: const Text("Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startUpload(File file, String name) async {
    setState(() => _isUploading = true);
    try {
      await _reportService.uploadReport(file, name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("වාර්තාව සාර්ථකව ඇතුළත් කළා!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ඇතුළත් කිරීම අසාර්ථකයි."), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String nic = user?.email?.split('@').first.trim() ?? "";

    return MathaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("වෛද්‍ය වාර්තා / MEDICAL REPORTS", 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1565C0))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medical_reports')
                  .where('motherNIC', isEqualTo: nic)
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("දෝෂයකි: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var report = snapshot.data!.docs[index];
                    DateTime date = (report['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    String formattedDate = DateFormat('yyyy MMM dd | hh:mm a').format(date);

                    return _buildReportTile(context, report['title'], report['imageUrl'], formattedDate);
                  },
                );
              },
            ),
            // Loading Overlay
            if (_isUploading)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFF06292)),
                      const SizedBox(height: 20),
                      Text("වාර්තාව ඇතුළත් වෙමින් පවතී...", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _pickAndUpload(context),
          backgroundColor: const Color(0xFFF06292),
          elevation: 4,
          icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
          label: const Text("නව වාර්තාවක්", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.note_add_rounded, size: 80, color: Colors.blueGrey.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          const Text("තවමත් වාර්තා ඇතුළත් කර නැත.", 
            style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          const Text("ඔබේ වාර්තා මෙතැනට එක් කරන්න.", style: TextStyle(color: Colors.black26, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, String title, String url, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: Hero(
          tag: url,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url, 
                width: 65, 
                height: 65, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(width: 65, height: 65, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
              ),
            ),
          ),
        ),
        title: Text(title, 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 12, color: Colors.black26),
                const SizedBox(width: 5),
                Text(date, style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.fullscreen_rounded, size: 20, color: Color(0xFFF06292)),
        ),
        onTap: () => _showImagePreview(context, url, title),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(tag: url, child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white), 
                      onPressed: () => Navigator.pop(context)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}