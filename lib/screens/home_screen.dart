import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../services/sos_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // ඊමේල් ලිපිනයෙන් NIC අංකය වෙන් කර ගැනීම
    String? currentNic;
    if (currentUser?.email != null) {
      currentNic = currentUser!.email!.split('@').first;
    }

    return Scaffold(
      backgroundColor: kDarkBackground,
      body: StreamBuilder<QuerySnapshot>(
        // දත්ත පද්ධතියේ 'nic' ක්ෂේත්‍රය සමඟ සසඳා බැලීම
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
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    "දත්ත සොයාගත නොහැක.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "NIC: $currentNic",
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ],
              ),
            );
          }

          // දත්ත පද්ධතියේ ඇති තොරතුරු ලබා ගැනීම
          var d = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          String fullName = d['fullName'] ?? "Mother";
          String midwife = d['assignedMidwife'] ?? "Mrs. Priyanka Perera";
          String riskStatus = d['riskStatus'] ?? "Normal";

          // ගැබ් කාලය සහ ප්‍රසූත දිනය ගණනය කිරීම [cite: 2026-02-06]
          DateTime lmpDate = (d['lmp'] as Timestamp).toDate();
          DateTime eddDate = (d['edd'] as Timestamp).toDate();

          int totalDays = DateTime.now().difference(lmpDate).inDays;
          int weeks = totalDays ~/ 7;
          int days = totalDays % 7;
          int daysToEdd = eddDate.difference(DateTime.now()).inDays;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(fullName),
                _buildSOSButton(context, midwife),
                _buildProgressCard(weeks, days, daysToEdd),

                _buildSectionTitle("Your Baby This Week | මේ සතියේ ඔබේ දරුවා"),
                _buildBabyGrowthCard(weeks),

                _buildSectionTitle("Health Status | සෞඛ්‍ය තත්ත්වය"),
                _buildRiskStatus(riskStatus),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI සහායක කොටස් (Helper Methods) ---

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ආයුබෝවන්, ${name.split(' ').first}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "නිරෝගී දවසක් ප්‍රාර්ථනා කරමු!",
                style: TextStyle(color: kPrimaryBlue),
              ),
            ],
          ),
          const CircleAvatar(
            backgroundColor: kPrimaryPink,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, String midwifeName) {
    return GestureDetector(
      onLongPress: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await SOSService().triggerSOS(midwifeName);
          messenger.showSnackBar(
            const SnackBar(
              content: Text("හදිසි පණිවිඩය යොමු කළා!"),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            const SnackBar(content: Text("දෝෂයකි: ස්ථානය ලබා ගත නොහැක.")),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
            SizedBox(width: 15),
            Text(
              "EMERGENCY SOS (Hold)",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int weeks, int days, int daysToEdd) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryBlue, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "ඔබේ ගැබ් කාලය",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeUnit(weeks, "සති"),
              const SizedBox(width: 20),
              _timeUnit(days, "දින"),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Text(
            "ප්‍රසූතියට තව දින $daysToEdd ක් ඇත",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeUnit(int val, String unit) {
    return Column(
      children: [
        Text(
          "$val",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildBabyGrowthCard(int week) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.child_care, color: kPrimaryBlue, size: 40),
          const SizedBox(height: 10),
          Text(
            "සතිය $week: දරුවාගේ වර්ධනය",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "දැන් ඔබේ දරුවා කුඩා දෙහි ගෙඩියක් තරම් විශාල වී ඇත. දරුවාගේ අත් සහ පාද දැන් හොඳින් නිර්මාණය වී අවසන්ය.",
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStatus(String status) {
    Color color = status == "High-Risk" ? Colors.redAccent : Colors.greenAccent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, color: color),
          const SizedBox(width: 15),
          Text(
            "ඔබේ තත්ත්වය: $status",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.white60),
      ),
    );
  }
}
