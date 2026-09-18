import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sos_service.dart';
import 'baby_cry_analyzer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _heartPulseController;
  Stream<QuerySnapshot>? _motherStream;

  @override
  void initState() {
    super.initState();
    _heartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? currentNic = currentUser?.email?.split('@').first;

    if (currentNic != null) {
      _motherStream = FirebaseFirestore.instance
          .collection('mothers')
          .where('nic', isEqualTo: currentNic)
          .limit(1)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _heartPulseController.dispose();
    super.dispose();
  }

  // --- Dynamic Greeting by Hour ---
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "සුබ උදෑසනක් / Good Morning 🌅";
    if (hour < 17) return "සුබ දහවලක් / Good Afternoon ☀️";
    return "සුබ සන්ධ්‍යාවක් / Good Evening 🌙";
  }

  // --- Baby Growth Logic ---
  Map<String, String> getBabyGrowthInfo(int week) {
    if (week <= 4) {
      return {
        "fruit": "කුඩා බීජයක් / Tiny Poppy Seed",
        "emoji": "🌱",
        "desc": "දරුවා දැන් කුඩා බීජයක් මෙන් ඉතා වේගයෙන් වර්ධනය වේ.",
      };
    }
    if (week <= 8) {
      return {
        "fruit": "මුද්‍රප්පලම් / Raspberry",
        "emoji": "🍇",
        "desc": "පුංචි අත් පා සහ හෘද ස්පන්දනය දැන් සක්‍රීය වෙමින් පවතී.",
      };
    }
    if (week <= 12) {
      return {
        "fruit": "දෙහි ගෙඩියක් / Lime",
        "emoji": "🍋",
        "desc": "දරුවාගේ ප්‍රධාන ඉන්ද්‍රියයන් සියල්ල සම්පූර්ණ වී ඇත.",
      };
    }
    if (week <= 20) {
      return {
        "fruit": "කෙසෙල් ගෙඩියක් / Banana",
        "emoji": "🍌",
        "desc": "දරුවාගේ චලනයන් දැන් ඔබට සෙමෙන් දැනෙන්නට පුළුවන.",
      };
    }
    if (week <= 28) {
      return {
        "fruit": "වම්බටු / Eggplant",
        "emoji": "🍆",
        "desc": "දරුවා දැන් ඇස් විවර කරන අතර ශබ්ද වලට ප්‍රතිචාර දක්වයි.",
      };
    }
    if (week <= 36) {
      return {
        "fruit": "පැපොල් ගෙඩියක් / Papaya",
        "emoji": "🥭",
        "desc": "දරුවාගේ පෙනහළු සහ මොළය මනාව පරිණත වෙමින් පවතී.",
      };
    }
    return {
      "fruit": "පුංචි බබෙක් / Fully Formed Baby",
      "emoji": "👶",
      "desc": "දරුවා මෙලොව එළිය දැකීමට සියලු අතින් සූදානම්!",
    };
  }

  // --- Daily Tips ---
  String getDailyTip() {
    int day = DateTime.now().weekday;
    List<String> tips = [
      "අද ප්‍රමාණවත් ලෙස ජලය පානය කළාද? (වතුර වීදුරු 8ක් වත් පානය කිරීම මවටත් බබාටත් ඉතා වැදගත් වේ).\nDid you drink enough water today? Staying hydrated is vital for you and baby.",
      "දැන් සුළු විවේකයක් ගන්න. විනාඩි දහයක් ඇස් පියාගෙන මෘදු සංගීතයකට සවන් දෙන්න.\nTake a 10-minute mindful pause to breathe deeply and rest.",
      "සැහැල්ලු ඇවිදීමක් ඔබේ ශරීරයේ රුධිර සංසරණය යහපත් කර මනස ප්‍රබෝධමත් කරයි.\nA gentle evening stroll boosts circulation and relaxes the mind.",
      "අද දින නියමිත විටමින් හා ෆෝලික් අම්ලය ලබා ගැනීමට අමතක නොකරන්න.\nRemember to take your prescribed prenatal vitamins and iron supplements.",
      "නැවුම් පලතුරු සහ කොළ එළවළු ඔබේ ආහාර වේලට එක්කර ගන්න.\nIncorporate fresh fruits, nuts, and leafy greens for natural nourishment.",
      "බබා සමඟ ආදරයෙන් කතා කරන්න. මවගේ හඬ දරුවාට සැනසීම ගෙන දෙයි.\nTalk gently to your bump. Your baby loves hearing your comforting voice.",
      "සතුටින් සිටින්න. ඔබගේ සතුට දරුවාගේ නිරෝගී වර්ධනයට මහෝපකාරී වේ.\nYour happiness and inner peace foster healthy fetal development."
    ];
    return tips[day % tips.length];
  }

  int _getTrimester(int weeks) {
    if (weeks <= 13) return 1;
    if (weeks <= 27) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    if (_motherStream == null) {
      return const Center(
        child: Text("කරුණාකර නැවත Login වන්න / Please login"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _motherStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF06292)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "දත්ත සොයාගත නොහැක / Data Not Found",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }

        var doc = snapshot.data!.docs.first;
        var d = doc.data() as Map<String, dynamic>;
        String fullName = d['fullName'] ?? "Mother";
        String midwife = d['assignedMidwife'] ?? "Mrs. Priyanka Perera";
        String riskStatus = d['riskStatus'] ?? "Normal";
        String? emergencyPhone = d['emergencyContact'];
        String profilePic = d['profilePic'] ?? 'assets/avatars/avatar1.png';

        DateTime lmpDate = (d['lmp'] != null)
            ? (d['lmp'] as Timestamp).toDate()
            : DateTime.now().subtract(const Duration(days: 70));
        DateTime eddDate = (d['edd'] != null)
            ? (d['edd'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 210));

        DateTime? nextClinic = d['nextClinicDate'] != null
            ? (d['nextClinicDate'] as Timestamp).toDate()
            : null;

        int weeks = DateTime.now().difference(lmpDate).inDays ~/ 7;
        if (weeks < 1) weeks = 1;
        if (weeks > 42) weeks = 40;
        int days = DateTime.now().difference(lmpDate).inDays % 7;
        int daysToEdd = eddDate.difference(DateTime.now()).inDays;
        if (daysToEdd < 0) daysToEdd = 0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // 1. Luminous Header Greeting
              _buildLuminousHeader(fullName, profilePic, weeks),
              const SizedBox(height: 18),

              // 2. Urgent Clinic Reminder (if available)
              if (nextClinic != null) _buildClinicReminderCard(nextClinic),

              // 3. Interactive Pregnancy Progress & Trimester Visualizer
              _buildInteractiveProgressCard(weeks, days, daysToEdd),
              const SizedBox(height: 20),

              // 4. Daily Mother's Wellness Hub (Mood & Water Tracker with persistent Firestore Sync)
              _MotherWellnessHub(motherId: doc.id),
              const SizedBox(height: 20),

              // 5. Baby Growth Comparison Card
              _buildBabyGrowthCard(weeks, getBabyGrowthInfo(weeks)),
              const SizedBox(height: 20),

              // 6. AI Dual Assistant Banner (Baby Cry Analyzer & Sarah Chatbot)
              _buildAIAssistantsBanner(context),
              const SizedBox(height: 20),

              // 7. Glowing SOS Emergency Assistance
              _GlowingSOSButton(
                midwife: midwife,
                emergencyPhone: emergencyPhone,
                docId: doc.id,
                onSetContact: (context, docId, phone) =>
                    _showSetContactDialog(context, docId, phone),
              ),
              const SizedBox(height: 20),

              // 8. Daily Health Tip
              _buildDailyTipCard(),
              const SizedBox(height: 16),

              // 9. Risk Status Indicator
              _buildRiskStatus(riskStatus),
              const SizedBox(height: 120), // Bottom padding for nav & FAB
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  1. LUMINOUS HEADER GREETING
  // ─────────────────────────────────────────────────────────────────
  Widget _buildLuminousHeader(String fullName, String profilePic, int weeks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF06292).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar with Glowing Ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF80AB), Color(0xFF00E5FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF06292).withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFF0F5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    profilePic,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.face_3_rounded,
                      color: Color(0xFFE91E63),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name & Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTimeGreeting(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Pregnancy Week Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              "සතිය $weeks",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  2. INTERACTIVE PREGNANCY JOURNEY & TRIMESTER CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildInteractiveProgressCard(int weeks, int days, int daysToEdd) {
    final int trimester = _getTrimester(weeks);
    final double progressPct = (weeks / 40.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2575FC).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Trimester Badge & Heartbeat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa_rounded, color: Color(0xFFFFD54F), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "ත්‍රෛමාසිකය $trimester (Trimester $trimester)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _heartPulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_heartPulseController.value * 0.18),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF4081),
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Middle Numbers: Weeks, Days & Days Left
          Row(
            children: [
              _buildMetricNumber("$weeks", "සති / WEEKS"),
              Container(
                height: 38,
                width: 1,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildMetricNumber("$days", "දින / DAYS"),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "ප්‍රසූතියට තව",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    "$daysToEdd දිනයි",
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    "Days Remaining",
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPct,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Week 1",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                "${(progressPct * 100).toStringAsFixed(0)}% Completed",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Week 40",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricNumber(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  4. BABY GROWTH COMPARISON CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBabyGrowthCard(int week, Map<String, String> info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(info['emoji'] ?? '👶', style: const TextStyle(fontSize: 42)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "සතිය $week • ${info['fruit']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info['desc'] ?? '',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  5. AI ASSISTANTS DUAL BANNER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAIAssistantsBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFF80AB).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFE91E63), size: 20),
              SizedBox(width: 8),
              Text(
                "මාතා AI සහයිකාවන් | AI Care Suite",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Baby Cry Analyzer
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black26,
                        pageBuilder: (_, __, ___) => const BabyCryAnalyzerScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("👶🎙️", style: TextStyle(fontSize: 24)),
                        SizedBox(height: 6),
                        Text(
                          "බිළිඳු හඬ AI",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE91E63)),
                        ),
                        Text(
                          "Cry Analyzer",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sarah Midwife AI
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("පහළ දකුණු පස ඇති Sarah AI බොත්තම ඔබන්න."),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF7E57C2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("👩‍⚕️💬", style: TextStyle(fontSize: 24)),
                        SizedBox(height: 6),
                        Text(
                          "Sarah Midwife",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7E57C2)),
                        ),
                        Text(
                          "24/7 AI Chatbot",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
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
  //  6. CLINIC REMINDER CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildClinicReminderCard(DateTime nextClinicDate) {
    final now = DateTime.now();
    final difference = nextClinicDate.difference(now).inDays;
    bool isUrgent = difference <= 2 && difference >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUrgent ? Colors.red.shade300 : Colors.blue.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.notification_important_rounded : Icons.calendar_today_rounded,
            color: isUrgent ? Colors.red : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? "අවධානය: මීළඟ සායනය ළඟදීම!" : "මීළඟ සායන දිනය (Next Clinic)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isUrgent ? Colors.red.shade900 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${nextClinicDate.year}-${nextClinicDate.month.toString().padLeft(2, '0')}-${nextClinicDate.day.toString().padLeft(2, '0')} ($difference days left)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  7. DAILY HEALTH TIP CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "අද දවසේ උපදෙස (Daily Tip):",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  getDailyTip(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  8. RISK STATUS INDICATOR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildRiskStatus(String status) {
    bool isHigh = status == "High-Risk";
    Color color = isHigh ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isHigh ? Icons.warning_amber_rounded : Icons.verified_user_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "සෞඛ්‍ය තත්ත්වය: $status / Status: $status",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetContactDialog(BuildContext context, String docId, String? currentPhone) {
    TextEditingController phoneController = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("හදිසි දුරකථන අංකය", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: "උදා: 0712345678",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("අවලංගුයි")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('mothers')
                  .doc(docId)
                  .update({'emergencyContact': phoneController.text});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("සුරකින්න"),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  MOTHER'S DAILY WELLNESS HUB (With Local & Cloud Persistence)
// ──────────────────────────────────────────────────────────────────
class _MotherWellnessHub extends StatefulWidget {
  final String motherId;

  const _MotherWellnessHub({required this.motherId});

  @override
  State<_MotherWellnessHub> createState() => _MotherWellnessHubState();
}

class _MotherWellnessHubState extends State<_MotherWellnessHub> {
  int _selectedMoodIndex = 0;
  int _waterGlassesDrank = 4;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _moods = [
    {"emoji": "😊", "label": "සතුටුයි", "en": "Happy", "color": const Color(0xFFFFD54F)},
    {"emoji": "🌸", "label": "සන්සුන්", "en": "Calm", "color": const Color(0xFF81C784)},
    {"emoji": "😴", "label": "මහන්සියි", "en": "Tired", "color": const Color(0xFF90CAF9)},
    {"emoji": "🥺", "label": "සංවේදී", "en": "Emotional", "color": const Color(0xFFF48FB1)},
  ];

  String get _todayDateKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadTodayWellness();
  }

  Future<void> _loadTodayWellness() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('mothers')
          .doc(widget.motherId)
          .collection('daily_wellness')
          .doc(_todayDateKey)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          if (data['moodIndex'] != null) {
            _selectedMoodIndex = data['moodIndex'] as int;
          }
          if (data['waterGlasses'] != null) {
            _waterGlassesDrank = data['waterGlasses'] as int;
          }
        });
      }
    } catch (_) {
      // Offline / fallback to initial state
    }
  }

  Future<void> _saveWellness() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final mood = _moods[_selectedMoodIndex];
      await FirebaseFirestore.instance
          .collection('mothers')
          .doc(widget.motherId)
          .collection('daily_wellness')
          .doc(_todayDateKey)
          .set({
        'date': _todayDateKey,
        'moodIndex': _selectedMoodIndex,
        'moodEmoji': mood['emoji'],
        'moodLabel': mood['label'],
        'waterGlasses': _waterGlassesDrank,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignored silently for smooth UX
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(Icons.spa_rounded, color: Color(0xFFF06292), size: 20),
              SizedBox(width: 8),
              Text(
                "අද දවසේ සුවතාවය | Daily Wellness Check",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mood Selector
          const Text(
            "ඔබට අද දැනෙන්නේ කෙසේද? (How do you feel?)",
            style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (index) {
              final isSelected = _selectedMoodIndex == index;
              final mood = _moods[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedMoodIndex = index);
                    _saveWellness();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("අද ඔබේ මනෝභාවය සටහන් විය: ${mood['label']} ${mood['emoji']}"),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFE91E63),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (mood['color'] as Color).withValues(alpha: 0.25)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (mood['color'] as Color) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(mood['emoji'], style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          mood['label'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? Colors.black87 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const Divider(height: 28),

          // Hydration Tracker (8 Glasses of Water)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop_rounded, color: Color(0xFF00B0FF), size: 18),
                      SizedBox(width: 4),
                      Text(
                        "ජලය පානය (Hydration)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "වීදුරු $_waterGlassesDrank / 8 ක් සම්පූර්ණයි",
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 22),
                    onPressed: () {
                      if (_waterGlassesDrank > 0) {
                        setState(() => _waterGlassesDrank--);
                        _saveWellness();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00B0FF), size: 28),
                    onPressed: () {
                      if (_waterGlassesDrank < 8) {
                        setState(() => _waterGlassesDrank++);
                        _saveWellness();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 8 Interactive Cups
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (i) {
              final isDrank = i < _waterGlassesDrank;
              return GestureDetector(
                onTap: () {
                  setState(() => _waterGlassesDrank = i + 1);
                  _saveWellness();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDrank
                        ? const Color(0xFF00B0FF).withValues(alpha: 0.18)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDrank ? const Color(0xFF00B0FF) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: isDrank ? const Color(0xFF00B0FF) : Colors.grey.shade300,
                    size: 16,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  GLOWING SOS EMERGENCY BUTTON WIDGET
// ──────────────────────────────────────────────────────────────────
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

class _GlowingSOSButtonState extends State<_GlowingSOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final SOSService _sosService = SOSService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.35 + (_controller.value * 0.25)),
                blurRadius: 20 + (_controller.value * 8),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "හදිසි ඇමතුම / EMERGENCY SOS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "වින්නඹු නිලධාරිනී: ${widget.midwife}",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Call Midwife
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (widget.emergencyPhone != null && widget.emergencyPhone!.isNotEmpty) {
                          final Uri url = Uri.parse("tel:${widget.emergencyPhone}");
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        } else {
                          widget.onSetContact(context, widget.docId, widget.emergencyPhone);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD50000),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text(
                        "අමතන්න (Call)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send Location SOS
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await _sosService.triggerSOS(widget.midwife, widget.emergencyPhone);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("හදිසි දැනුම්දීම (SOS) යවන ලදී!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("දෝෂයකි: $e"), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text(
                        "ස්ථානය යවන්න",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
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