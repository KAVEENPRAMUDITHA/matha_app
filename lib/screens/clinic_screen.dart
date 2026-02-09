import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/matha_background.dart';

class ClinicScreen extends StatelessWidget {
  const ClinicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    
    // NIC එක ලබා ගැනීම සහ දෙපස ඇති අනවශ්‍ය ඉඩ (Spaces) ඉවත් කිරීම
    String? currentNic = user?.email?.split('@').first.trim();

    return MathaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "සායන වාර්තා / CLINIC RECORDS",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1565C0)),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          // *** Collection එකේ නම නිවැරදි කළා: 'clinic_reports' ***
          stream: FirebaseFirestore.instance
              .collection('clinic_reports') 
              .where('motherNIC', isEqualTo: currentNic)
              .orderBy('visitDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // දෝෂයක් ආවොත් එය පෙන්වීමට (Index Link එක මෙතැන පෙනේවි)
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "දෝෂයකි: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(currentNic);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var record = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildClinicCard(context, record);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? nic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: Colors.blueGrey.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text(
            "සායන වාර්තා හමුවුනේ නැත.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "Collection: clinic_reports\nNIC: $nic",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black26, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, Map<String, dynamic> data) {
    // දින ලබා ගැනීම
    DateTime visitDate = DateTime.now();
    if (data['visitDate'] != null) {
      visitDate = (data['visitDate'] as Timestamp).toDate();
    }
    
    String formattedDate = "${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFFF06292),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF06292).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFF06292), size: 22),
          ),
          title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
          subtitle: const Text("විස්තර බැලීමට ඔබන්න", style: TextStyle(fontSize: 11, color: Colors.black38)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
              child: Column(
                children: [
                  const Divider(),
                  _buildDataRow(Icons.monitor_weight_outlined, "බර (Weight)", "${data['weight'] ?? '--'} kg"),
                  _buildDataRow(Icons.speed_rounded, "රුධිර පීඩනය (BP)", "${data['bloodPressure'] ?? '--'} mmHg"),
                  _buildDataRow(Icons.favorite_rounded, "හෘද ස්පන්දනය (FHR)", "${data['fetalHeartRate'] ?? '--'} bpm"),
                  _buildDataRow(Icons.straighten_rounded, "ගර්භාෂ උස (SFH)", "${data['sfh'] ?? '--'} cm"),
                  _buildDataRow(Icons.child_friendly_rounded, "ළදරු චලන (Kicks)", "${data['kickCount'] ?? '--'} per hour"),

                  const SizedBox(height: 15),
                  // Urine Tests
                  if (data['urineTests'] != null)
                    _buildSubDataBox("මුත්‍රා පරීක්ෂණ / Urine Tests", [
                      "සීනි (Sugar): ${data['urineTests']['sugar'] ?? 'N/A'}",
                      "ඇල්බියුමින් (Albumin): ${data['urineTests']['albumin'] ?? 'N/A'}",
                    ]),

                  const SizedBox(height: 10),
                  // Supplements
                  if (data['supplements'] != null)
                    _buildSubDataBox("ලබාදුන් විටමින් / Supplements", [
                      "යකඩ පෙති (Iron): ${data['supplements']['ironQty'] ?? '0'} tablets",
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubDataBox(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          const SizedBox(height: 5),
          ...items.map((item) => Text("• $item", style: const TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent.shade100),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
        ],
      ),
    );
  }
}