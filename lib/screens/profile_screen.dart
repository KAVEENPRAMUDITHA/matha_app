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
  String selectedAvatar = 'assets/avatars/avatar1.png';

  void _showEditDialog(String fieldName, String currentValue, String docId, String label) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.98),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "$label වෙනස් කරන්න",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1565C0),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF06292)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("අවලංගුයි", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF06292),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('mothers')
                  .doc(docId)
                  .update({fieldName: controller.text});
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text("සුරකින්න", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.98),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.redAccent,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "ගිණුමෙන් ඉවත්වීම",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "ඔබට මෙම ගිණුමෙන් ඉවත් වීමට අවශ්‍යද?",
              style: TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("නැත (Cancel)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await authService.signOut();
                    },
                    child: const Text("ඔව් (Logout)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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
          title: const Text(
            "මගේ ගිණුම / HEALTH PASSPORT",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1565C0),
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _showLogoutDialog(context, authService),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('mothers')
              .where('nic', isEqualTo: currentNic)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("දත්ත සොයාගත නොහැක / No Data"));
            }

            var doc = snapshot.data!.docs.first;
            var userData = doc.data() as Map<String, dynamic>;
            String currentProfilePic = userData['profilePic'] ?? selectedAvatar;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                children: [
                  // Passport Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2575FC).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AvatarPicker(
                                onAvatarSelected: (imagePath) async {
                                  await FirebaseFirestore.instance
                                      .collection('mothers')
                                      .doc(doc.id)
                                      .update({'profilePic': imagePath});
                                  setState(() => selectedAvatar = imagePath);
                                },
                              ),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFFFF0F5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(46),
                                    child: Image.asset(currentProfilePic),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4081),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          userData['fullName'] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "🌸 ලියාපදිංචි මවක් • Registered Mother",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Obstetric Passport (Gravida, Parity, Blood Group, Height)
                  _buildObstetricPassportCard(userData),

                  // 2. Pregnancy & Delivery History (Past Deliveries & Active Cycles)
                  _buildPregnancyHistorySection(doc.id, userData),

                  // 3. Assigned Midwife Card
                  if (userData['assignedMidwife'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              shape: BoxShape.circle,
                            ),
                            child: const Text("👩‍⚕️", style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "පවරන ලද වින්නඹු නිලධාරිනිය",
                                  style: TextStyle(fontSize: 10.5, color: Colors.black45, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userData['assignedMidwife'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. Info Tiles
                  _buildInfoTile("හැඳුනුම්පත් අංකය / NIC", userData['nic'] ?? "N/A", Icons.badge_outlined, false, null),
                  _buildInfoTile("ඊමේල් ලිපිනය / EMAIL", userData['email'] ?? "N/A", Icons.mail_outline_rounded, true, () => _showEditDialog('email', userData['email'] ?? "", doc.id, "ඊමේල් ලිපිනය")),
                  _buildInfoTile("දුරකථන අංකය / PHONE", userData['phone'] ?? "N/A", Icons.phone_android_rounded, true, () => _showEditDialog('phone', userData['phone'] ?? "", doc.id, "දුරකථන අංකය")),
                  _buildInfoTile("ප්‍රදේශය / MOH AREA", userData['mohArea'] ?? "N/A", Icons.map_outlined, false, null),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  OBSTETRIC PASSPORT (Gravida & Parity)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildObstetricPassportCard(Map<String, dynamic> userData) {
    final int gravida = userData['gravida'] ?? 1;
    final int parity = userData['parity'] ?? (gravida > 1 ? gravida - 1 : 0);
    final String bloodGroup = userData['bloodGroup'] ?? "N/A";
    final dynamic height = userData['height'] ?? "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF48FB1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge_rounded, color: Color(0xFFE91E63), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "මාතෘ සෞඛ්‍ය විස්තර • Obstetric Passport",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Gravida Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF80CBC4), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ගර්භණීභාවය (Gravida)",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "G$gravida ($gravida වන දරු ගැබ)",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Parity Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFBE9E7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCC80), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "පෙර ප්‍රසූති (Parity)",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "P$parity ($parity දරු උපත්)",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Blood Group
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bloodtype_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "රුධිරය: $bloodGroup",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Height
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.height_rounded, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "උස: $height cm",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  PREGNANCY & DELIVERY HISTORY
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPregnancyHistorySection(String motherDocId, Map<String, dynamic> userData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E24AA).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E5F5),
                  shape: BoxShape.circle,
                ),
                child: const Text("🌸", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "ප්‍රසූති ඉතිහාසය සහ වාර්තා\nPregnancy & Delivery History",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF6A1B9A),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stream of past pregnancies from subcollection
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mothers')
                .doc(motherDocId)
                .collection('pregnancies')
                .orderBy('gravidaNumber', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Color(0xFFAB47BC), strokeWidth: 2),
                  ),
                );
              }

              final docs = snap.data?.docs ?? [];

              if (docs.isEmpty) {
                final int currentGravida = userData['gravida'] ?? 1;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFFAB47BC), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            currentGravida == 1
                                ? "පළමු දරු ගැබ (1st Pregnancy • G1P0)"
                                : "$currentGravida වන දරු ගැබ (Active • G$currentGravida)",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentGravida == 1
                            ? "මෙය ඔබගේ පළමු දරු ගැබයි. සාර්ථක හා නිරෝගී ප්‍රසූතියකට ආශිර්වාද කරමු!"
                            : "දැනට මෙම දරු ගැබ ක්‍රියාකාරී තත්ත්වයේ (Active) පවතී.",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: docs.map((pDoc) {
                  final data = pDoc.data() as Map<String, dynamic>;
                  final int gNum = data['gravidaNumber'] ?? 1;
                  final String status = data['status'] ?? 'Active';
                  final bool isCompleted = status.toLowerCase() == 'completed' || status.toLowerCase() == 'delivered';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFF9FBE7) : const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCompleted ? const Color(0xFFC0CA33) : const Color(0xFFB39DDB),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCompleted
                                  ? "👶 $gNum වන දරු උපත (G$gNum • Completed)"
                                  : "🤰 $gNum වන දරු ගැබ (G$gNum • Active)",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                color: isCompleted ? const Color(0xFF558B2F) : const Color(0xFF512DA8),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFF7CB342) : const Color(0xFF673AB7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isCompleted ? "සාර්ථකව අවසන්" : "වත්මන් දරු ගැබ",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isCompleted) ...[
                          if (data['deliveryDate'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                "📅 ප්‍රසූත දිනය: ${data['deliveryDate']}",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                          if (data['birthWeight'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                "⚖️ දරුවාගේ උපන් බර: ${data['birthWeight']} kg",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                          if (data['deliveryMethod'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                "🏥 ප්‍රසූත ක්‍රමය: ${data['deliveryMethod']}",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                          if (data['hospital'] != null)
                            Text(
                              "📍 රෝහල: ${data['hospital']}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                        ] else ...[
                          if (data['edd'] != null)
                            Text(
                              "🎯 අපේක්ෂිත ප්‍රසූත දිනය (EDD): ${data['edd']}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    bool isEditable,
    VoidCallback? onEdit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFF06292), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E88E5), size: 26),
            ),
        ],
      ),
    );
  }
}