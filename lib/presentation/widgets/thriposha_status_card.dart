import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ThriposhaStatusCard extends StatelessWidget {
  final String motherId;
  const ThriposhaStatusCard({super.key, required this.motherId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('mothers').doc(motherId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final DateTime? nextDueDate = (data['nextThriposhaDueDate'] as Timestamp?)?.toDate();
        final DateTime? lastDate = (data['lastThriposhaDate'] as Timestamp?)?.toDate();
        final int lastPackets = (data['lastThriposhaPackets'] as num?)?.toInt() ?? 2;

        int daysRemaining = 0;
        if (nextDueDate != null) {
          daysRemaining = nextDueDate.difference(DateTime.now()).inDays;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade900.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ත්‍රිපෝෂ බෙදාහැරීමේ තොරතුරු",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Thriposha Distribution Status",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      daysRemaining <= 0 ? "අද ලබාගන්න" : "තව දින $daysRemaining යි",
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("අවසන් වරට ලබාගත් දිනය", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        lastDate != null
                            ? "${DateFormat('yyyy-MM-dd').format(lastDate)} ($lastPackets pkts)"
                            : "ලබාගෙන නැත",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("මීළඟට ලබාගත යුතු දිනය", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        nextDueDate != null ? DateFormat('yyyy-MM-dd').format(nextDueDate) : "නියම කර නැත",
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
