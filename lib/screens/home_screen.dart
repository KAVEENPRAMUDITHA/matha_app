import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/matha_background.dart'; 
import '../services/sos_service.dart';
import 'baby_cry_analyzer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- Baby Growth Logic ---
  Map<String, String> getBabyGrowthInfo(int week) {
    if (week <= 4) return {"fruit": "බීජයක් / Tiny Seed", "emoji": "🌱", "desc": "දරුවා දැන් කුඩා බීජයක් මෙන් වේ."};
    if (week <= 8) return {"fruit": "මුද්‍රප්පලම් / Raspberry", "emoji": "🍇", "desc": "දරුවා මුද්‍රප්පලම් ගෙඩියක් තරම් වේ."};
    if (week <= 12) return {"fruit": "දෙහි ගෙඩියක් / Lime", "emoji": "🍋", "desc": "දරුවා දැන් දෙහි ගෙඩියක් තරම් වේ."};
    if (week <= 24) return {"fruit": "පැපොල් ගෙඩියක් / Papaya", "emoji": "🥭", "desc": "දරුවා දැන් පැපොල් ගෙඩියක් තරම් වේ."};
    return {"fruit": "පුංචි බබෙක් / Fully Formed Baby", "emoji": "👶", "desc": "දරුවා දැන් මෙලොවට ඒමට සූදානම්!"};
  }

  // --- Daily Tips ---
  String getDailyTip() {
    int day = DateTime.now().weekday;
    List<String> tips = [
      "අද ඇති වෙන්න වතුර බිව්වද? පොඩ්ඩක් මතක් කරලා බලන්න.\nDid you drink enough water today? Just a quick reminder.",
      "දැන් පොඩ්ඩක් මහන්සි ඇති. විනාඩි දහයක්වත් ඇස් දෙක පියාගෙන ඉන්න.\nYou might be feeling tired. Try to rest for at least ten minutes.",
      "පොඩ්ඩක් එළියට ගිහින් ඇවිදලා එමුද? හිතටත් ලොකු නිදහසක් දැනේවි.\nHow about a short walk outside? It will make you feel much better.",
      "අද විටමින් ටික ගත්තද? අමතක වුණා නම් දැන්ම ගන්න.\nDid you take your vitamins today? If not, now is a good time.",
      "බඩගිනි වුණාම කන්න මොනවා හරි පලතුරක් ළඟින් තියාගන්න.\nKeep some fruit nearby to snack on whenever you feel hungry.",
      "ඔයාටයි බබාලාටයි දෙන්නටම ගුණ කෑමක් අද වේලට එකතු කරගමු.\nLet’s add something healthy to your meal for both you and the baby.",
      "හොඳට නිදාගන්න. ඔයාගේ ශරීරයට දැන් ඒ විවේකය ගොඩක් ඕනේ.\nGet some good sleep. Your body really needs the rest right now.",
      "දැන් බබාට ඔයා කියන දේවල් ඇහෙනවා. ඉතින් පොඩ්ඩක් එයා එක්ක කතා කරන්න.\nThe baby can hear you now. Go ahead and have a little chat with them.",
      "හිතට වද දෙන ප්‍රශ්න අමතක කරලා, ලස්සන සින්දුවක් අහන්න.\nForget your worries for a moment and listen to some relaxing music.",
      "අද ඔයාට කොහොමද? හිතට දැනෙන දේ අපිත් එක්ක බෙදාගන්න.\nHow are you feeling today? Feel free to share what’s on your mind.",
      "ඔයා අද හරිම ලස්සනයි. ඒ හිනාව දිගටම තියාගන්න.\nYou look beautiful today. Keep that smile glowing."
    ];
    return tips[day % tips.length];
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentNic = currentUser?.email?.split('@').first;

    return MathaBackground(
      child: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text("දත්ත සොයාගත නොහැක / Data Not Found"));
          }

          var doc = snapshot.data!.docs.first;
          var d = doc.data() as Map<String, dynamic>;
          String fullName = d['fullName'] ?? "Mother";
          String midwife = d['assignedMidwife'] ?? "Mrs. Priyanka Perera";
          String riskStatus = d['riskStatus'] ?? "Normal";
          String? emergencyPhone = d['emergencyContact'];
          String profilePic = d['profilePic'] ?? 'assets/avatars/avatar1.png';

          DateTime lmpDate = (d['lmp'] as Timestamp).toDate();
          DateTime eddDate = (d['edd'] as Timestamp).toDate();
          
          // සායන දිනය ලබා ගැනීම
          DateTime? nextClinic = d['nextClinicDate'] != null 
              ? (d['nextClinicDate'] as Timestamp).toDate() 
              : null;

          int weeks = DateTime.now().difference(lmpDate).inDays ~/ 7;
          int days = DateTime.now().difference(lmpDate).inDays % 7;
          int daysToEdd = eddDate.difference(DateTime.now()).inDays;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildHeader(fullName, profilePic),
                
                // --- සායන මතක් කිරීමේ Card එක මෙතැනට එක් කර ඇත ---
                if (nextClinic != null) _buildClinicReminder(nextClinic),
                
                _GlowingSOSButton(
                  midwife: midwife,
                  emergencyPhone: emergencyPhone,
                  docId: doc.id,
                  onSetContact: (context, docId, phone) => _showSetContactDialog(context, docId, phone),
                ),
                const SizedBox(height: 20),
                _buildProgressCard(weeks, days, daysToEdd),
                _buildSectionTitle("Daily Health Tip | අද දවසේ උපදෙස්"),
                _buildDailyTipCard(),
                _buildSectionTitle("Baby's Growth | දරුවාගේ වර්ධනය"),
                _buildBabyGrowthCard(weeks, getBabyGrowthInfo(weeks)),
                _buildSectionTitle("AI Baby Cry Analyzer | බිළිඳු හඬ විශ්ලේෂකය"),
                _buildBabyCryCard(context),
                _buildSectionTitle("Health Status | සෞඛ්‍ය තත්ත්වය"),
                _buildRiskStatus(riskStatus),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- සායන මතක් කිරීමේ Card එක ---
  Widget _buildClinicReminder(DateTime nextClinicDate) {
    final now = DateTime.now();
    final difference = nextClinicDate.difference(now).inDays;
    bool isUrgent = difference <= 2 && difference >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.blue.shade200, 
          width: 2
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.notification_important_rounded : Icons.calendar_today_rounded,
            color: isUrgent ? Colors.red : Colors.blue.shade700,
            size: 35,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? "අවධානය යොමු කරන්න!" : "මීළඟ සායන දිනය",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isUrgent ? Colors.red.shade900 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "දිනය: ${nextClinicDate.year}-${nextClinicDate.month}-${nextClinicDate.day}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                if (isUrgent)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "ඔබේ සායනය ඉතා ළඟයි!",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String avatarPath) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ආයුබෝවන්, ${name.split(' ').first}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
              ),
              const Text("නිරෝගී දවසක්! 🌸", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE3F2FD),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(avatarPath, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetContactDialog(BuildContext context, String docId, String? currentPhone) {
    TextEditingController controller = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.contact_phone_rounded, color: Colors.blueAccent, size: 40),
            ),
            const SizedBox(height: 15),
            const Text("හදිසි ඇමතුම් අංකය", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1565C0), fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("හදිසි අවස්ථාවකදී ඇමතුමක් ලබා ගැනීමට ඔබගේ පවුලේ අයෙකුගේ අංකයක් මෙහි ඇතුළත් කරන්න.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                labelText: "Phone Number",
                prefixIcon: const Icon(Icons.phone_android_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("අවලංගුයි")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('mothers').doc(docId).update({'emergencyContact': controller.text});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("සුරකින්න"),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int weeks, int days, int daysToEdd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF06292), Color(0xFFE91E63)]), borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          const Text("ඔබේ ගැබ් කාලය / Pregnancy Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _timeBox(weeks, "සති / WEEKS"),
            const SizedBox(width: 30),
            _timeBox(days, "දින / DAYS"),
          ]),
          const Divider(color: Colors.white24, height: 30),
          Text("ප්‍රසූතියට තව දින $daysToEdd කි / Days left: $daysToEdd", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _timeBox(int val, String unit) {
    return Column(children: [
      Text("$val", style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900)),
      Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    ]);
  }

  Widget _buildBabyGrowthCard(int week, Map<String, String> info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Text(info['emoji']!, style: const TextStyle(fontSize: 50)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("සතිය $week - ${info['fruit']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
                Text(info['desc']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabyCryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFFF80AB).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.08),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF80AB), Color(0xFFE91E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text("👶🎙️", style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "බිළිඳු හඬ විශ්ලේෂණය",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "දරුවා අඬන හේතුව තත්පර 5න් AI මඟින් දැනගන්න",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black26,
                    pageBuilder: (_, __, ___) => const BabyCryAnalyzerScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: const Text(
                "හඬ පරීක්ෂා කරන්න (Analyze Cry)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.lightBlue.shade50.withOpacity(0.7), Colors.white.withOpacity(0.9)]), borderRadius: BorderRadius.circular(25)),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.orangeAccent, size: 28),
        const SizedBox(width: 15),
        Expanded(child: Text(getDailyTip(), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, height: 1.6))),
      ]),
    );
  }

  Widget _buildRiskStatus(String status) {
    Color color = status == "High-Risk" ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.shield_moon_rounded, color: color),
        const SizedBox(width: 15),
        Text("තත්ත්වය: $status / Status: $status", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))));
  }
}

class _GlowingSOSButton extends StatefulWidget {
  final String midwife;
  final String? emergencyPhone;
  final String docId;
  final Function(BuildContext, String, String?) onSetContact;

  const _GlowingSOSButton({
    required this.midwife,
    required this.emergencyPhone,
    required this.docId,
    required this.onSetContact,
  });

  @override
  State<_GlowingSOSButton> createState() => _GlowingSOSButtonState();
}

class _GlowingSOSButtonState extends State<_GlowingSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 2.0, end: 15.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.3),
                blurRadius: _animation.value,
                spreadRadius: _animation.value / 2,
              )
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.redAccent),
                  onPressed: () => widget.onSetContact(context, widget.docId, widget.emergencyPhone),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
                  onLongPress: () async {
                    if (widget.emergencyPhone == null || widget.emergencyPhone!.isEmpty) {
                      widget.onSetContact(context, widget.docId, null);
                    } else {
                      await SOSService().triggerSOS(widget.midwife, widget.emergencyPhone);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("හදිසි පණිවිඩය සහ ඇමතුම යොමු කළා!"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        const Icon(Icons.emergency_share, color: Colors.red, size: 45),
                        const SizedBox(height: 10),
                        const Text("EMERGENCY SOS", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          widget.emergencyPhone == null ? "තිත් 3 ඔබා හදිසි අංකයක් එක් කරන්න" : "Call: ${widget.emergencyPhone}",
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}