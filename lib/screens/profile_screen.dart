import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    // NIC අංකය ඊමේල් ලිපිනයෙන් වෙන් කර ගැනීම
    String? currentNic;
    if (user?.email != null) {
      currentNic = user!.email!.split('@').first;
    }

    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text(
          "මගේ ගිණුම",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kCardColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. ටැග් එක 'nic' ලෙස නිවැරදි කළා
        stream: FirebaseFirestore.instance
            .collection('mothers')
            .where('nic', isEqualTo: currentNic)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryBlue),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.white24),
                  const SizedBox(height: 20),
                  const Text(
                    "ගිණුම් දත්ත සොයාගත නොහැක.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "NIC: $currentNic",
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          var userData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Picture & Name
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: kPrimaryBlue,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  // 2. ටැග් එක 'fullName' ලෙස නිවැරදි කළා
                  userData['fullName'] ?? "නම සඳහන් කර නැත",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Info List
                _buildInfoTile(
                  "හැඳුනුම්පත් අංකය",
                  // 3. ටැග් එක 'nic' ලෙස නිවැරදි කළා
                  userData['nic'] ?? "N/A",
                  Icons.badge,
                ),
                _buildInfoTile(
                  "ඊමේල් ලිපිනය",
                  userData['email'] ?? "N/A",
                  Icons.email,
                ),
                _buildInfoTile(
                  "දුරකථන අංකය",
                  userData['phone'] ?? "සඳහන් කර නැත",
                  Icons.phone,
                ),
                _buildInfoTile(
                  "ප්‍රදේශය (MOH Area)",
                  userData['mohArea'] ?? "සඳහන් කර නැත",
                  Icons.location_on,
                ),

                const SizedBox(height: 40),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    // Logout වූ පසු Login තිරයට යාම ස්වයංක්‍රීයව MainWrapper හරහා සිදුවේ
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "පද්ධතියෙන් ඉවත් වන්න",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: kPrimaryPink),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
