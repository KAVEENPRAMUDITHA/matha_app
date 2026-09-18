import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/matha_background.dart';

class ClinicScreen extends StatelessWidget {
  const ClinicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    String? currentNic = user?.email?.split('@').first.trim();

    return MathaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "සායන වාර්තා / CLINIC TIMELINE",
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
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clinic_reports')
              .where('motherNIC', isEqualTo: currentNic)
              .orderBy('visitDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "දෝෂයකි: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFF06292)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(currentNic);
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var record = docs[index].data() as Map<String, dynamic>;
                final bool isLatest = index == 0;
                return _buildTimelineClinicCard(context, record, isLatest, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? nic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 70,
                color: Color(0xFF64B5F6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "තවමත් සායන වාර්තා සටහන් කර නැත.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "ඔබේ ප්‍රදේශයේ වින්නඹු නිලධාරිනිය විසින් සායන වාර්තා මෙහි යාවත්කාලීන කරනු ඇත.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineClinicCard(
    BuildContext context,
    Map<String, dynamic> data,
    bool isLatest,
    int index,
  ) {
    DateTime visitDate = DateTime.now();
    if (data['visitDate'] != null) {
      visitDate = (data['visitDate'] as Timestamp).toDate();
    }

    String formattedDate =
        "${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isLatest ? const Color(0xFFF06292).withValues(alpha: 0.6) : Colors.white,
          width: isLatest ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLatest
                ? const Color(0xFFF06292).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isLatest,
          iconColor: const Color(0xFFF06292),
          collapsedIconColor: Colors.grey,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLatest
                    ? [const Color(0xFFF06292), const Color(0xFFE91E63)]
                    : [const Color(0xFF64B5F6), const Color(0xFF1E88E5)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLatest ? Icons.star_rounded : Icons.event_note_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 8),
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Latest",
                    style: TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            "සායන අංක #${index + 1} • Clinic Visit Record",
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: Column(
                children: [
                  const Divider(height: 20),

                  // Key Vitals Badges Grid
                  Row(
                    children: [
                      _buildVitalBox("බර (Weight)", "${data['weight'] ?? '--'} kg", Icons.monitor_weight_outlined, const Color(0xFFE91E63)),
                      const SizedBox(width: 10),
                      _buildVitalBox("රුධිර පීඩනය (BP)", "${data['bloodPressure'] ?? '--'}", Icons.speed_rounded, const Color(0xFF1E88E5)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildVitalBox("හෘද ස්පන්දනය (FHR)", "${data['fetalHeartRate'] ?? '--'} bpm", Icons.favorite_rounded, const Color(0xFFFF5252)),
                      const SizedBox(width: 10),
                      _buildVitalBox("ගර්භාෂ උස (SFH)", "${data['sfh'] ?? '--'} cm", Icons.straighten_rounded, const Color(0xFF00B0FF)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Urine Tests
                  if (data['urineTests'] != null)
                    _buildSubDataBox("🧪 මුත්‍රා පරීක්ෂණ / Urine Tests", [
                      "සීනි (Sugar): ${data['urineTests']['sugar'] ?? 'N/A'}",
                      "ඇල්බියුමින් (Albumin): ${data['urineTests']['albumin'] ?? 'N/A'}",
                    ]),

                  // Supplements
                  if (data['supplements'] != null) ...[
                    const SizedBox(height: 10),
                    _buildSubDataBox("💊 ලබාදුන් විටමින් / Supplements", [
                      "යකඩ පෙති (Iron): ${data['supplements']['ironQty'] ?? '0'} tablets",
                      "ෆෝලික් අම්ලය (Folic Acid): ${data['supplements']['folicQty'] ?? '0'} tablets",
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubDataBox(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                "• $item",
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}