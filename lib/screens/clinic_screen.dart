import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/colors.dart';

class ClinicScreen extends StatelessWidget {
  const ClinicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ලොග් වී සිටින මවගේ UID එක සෘජුවම ලබා ගැනීම
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text(
          "සායනික වාර්තා",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kCardColor,
        elevation: 0,
      ),
      body: userId == null
          ? const Center(child: Text("කරුණාකර නැවත ලොග් වන්න."))
          : StreamBuilder<DocumentSnapshot>(
              // මවගේ UID එකට අදාළ ලේඛනය (Document) ලබා ගැනීම
              stream: FirebaseFirestore.instance
                  .collection('mothers')
                  .doc(userId)
                  .snapshots(),
              builder: (context, motherSnapshot) {
                if (motherSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                }

                if (!motherSnapshot.hasData || !motherSnapshot.data!.exists) {
                  return const Center(
                    child: Text("මවගේ දත්ත සොයාගත නොහැක.", style: TextStyle(color: Colors.white54)),
                  );
                }

                // සායනික වාර්තා (Sub-collection) ලබා ගැනීම
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('mothers')
                      .doc(userId)
                      .collection('clinic_records')
                      .orderBy('date', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("තවමත් සායනික දත්ත ඇතුළත් කර නොමැත.", style: TextStyle(color: Colors.white54)),
                      );
                    }

                    var records = snapshot.data!.docs;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "බරෙහි වෙනස්වීම (Weight Gain)",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 20),

                          // බර පෙන්වන ප්‍රස්ථාරය
                          _buildWeightChart(records),

                          const SizedBox(height: 40),
                          const Text(
                            "අලුත්ම දත්ත (Latest Metrics)",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 15),

                          // රුධිර පීඩනය (BP) පෙන්වීම
                          _buildMetricCard(
                            "Blood Pressure",
                            "${records.last['systolicBP']}/${records.last['diastolicBP']} mmHg",
                            Icons.monitor_heart,
                            kPrimaryPink,
                          ),

                          // වර්තමාන බර පෙන්වීම
                          _buildMetricCard(
                            "Current Weight",
                            "${records.last['weight']} kg",
                            Icons.scale,
                            kPrimaryBlue,
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // --- බර පෙන්වන ප්‍රස්ථාරය (Line Chart) ---
  Widget _buildWeightChart(List<QueryDocumentSnapshot> records) {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: records.asMap().entries.map((e) {
                return FlSpot(
                  e.key.toDouble(),
                  (e.value['weight'] as num).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: kPrimaryBlue,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: kPrimaryBlue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}