import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/matha_background.dart';
import '../widgets/avatar_picker.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Default පින්තූරය
  String selectedAvatar = 'assets/avatars/avatar1.png';

  void _showEditDialog(String fieldName, String currentValue, String docId, String label) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text("$label වෙනස් කරන්න", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF06292)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("අවලංගුයි", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF06292), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('mothers').doc(docId).update({fieldName: controller.text});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("සුරකින්න", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 50)),
            const SizedBox(height: 25),
            const Text("ඉවත්වීම / LOGOUT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1565C0))),
            const SizedBox(height: 35),
            Row(
              children: [
                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () => Navigator.pop(context), child: const Text("නැත / NO", style: TextStyle(color: Colors.grey)))),
                const SizedBox(width: 15),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () async { Navigator.pop(context); await authService.signOut(); }, child: const Text("ඔව් / YES", style: TextStyle(color: Colors.white)))),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();
    String? currentNic = user?.email?.split('@').first;

    return MathaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("මගේ ගිණුම / PROFILE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1565C0))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(onPressed: () => _showLogoutDialog(context, authService), icon: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24))),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('mothers').where('nic', isEqualTo: currentNic).limit(1).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("දත්ත සොයාගත නොහැක"));

            var doc = snapshot.data!.docs.first;
            var userData = doc.data() as Map<String, dynamic>;
            
            // Database එකේ පින්තූරයක් තිබේ නම් එය ලබා ගැනීම
            String currentProfilePic = userData['profilePic'] ?? selectedAvatar;

            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: constraints.maxHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AvatarPicker(onAvatarSelected: (imagePath) async {
                              // Database එක Update කිරීම
                              await FirebaseFirestore.instance.collection('mothers').doc(doc.id).update({'profilePic': imagePath});
                              setState(() => selectedAvatar = imagePath);
                            }),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 20)]), child: CircleAvatar(radius: constraints.maxHeight * 0.09, backgroundColor: const Color(0xFFE3F2FD), child: ClipRRect(borderRadius: BorderRadius.circular(60), child: Image.asset(currentProfilePic)))),
                            const CircleAvatar(radius: 18, backgroundColor: Color(0xFFF06292), child: Icon(Icons.edit_rounded, size: 16, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(userData['fullName'] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
                      const Text("ලියාපදිංචි මවක් / Registered Mother", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 30),
                      _buildInfoTile("හැඳුනුම්පත් අංකය / NIC", userData['nic'] ?? "N/A", Icons.badge_outlined, false, null),
                      _buildInfoTile("ඊමේල් ලිපිනය / EMAIL", userData['email'] ?? "N/A", Icons.mail_outline_rounded, true, () => _showEditDialog('email', userData['email'] ?? "", doc.id, "ඊමේල් ලිපිනය")),
                      _buildInfoTile("දුරකථන අංකය / PHONE", userData['phone'] ?? "N/A", Icons.phone_android_rounded, true, () => _showEditDialog('phone', userData['phone'] ?? "", doc.id, "දුරකථන අංකය")),
                      _buildInfoTile("ප්‍රදේශය / MOH AREA", userData['mohArea'] ?? "N/A", Icons.map_outlined, false, null),
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, bool isEditable, VoidCallback? onEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white, width: 2)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF06292), size: 22),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)))])),
          if (isEditable) IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 26)),
        ],
      ),
    );
  }
}