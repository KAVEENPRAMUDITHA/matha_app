import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/community_message.dart';
import '../services/community_chat_service.dart';

class CommunityChatScreen extends StatefulWidget {
  final bool isTab;
  const CommunityChatScreen({super.key, this.isTab = true});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final CommunityChatService _chatService = CommunityChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedTag = 'සාමාන්‍ය';
  String _activeFilter = 'සියල්ල';
  bool _isSending = false;

  final List<String> _tags = ['සාමාන්‍ය', 'ප්‍රශ්නයක්', 'උපදෙසක්', 'අත්දැකීමක්'];
  final List<String> _filters = ['සියල්ල', '💬 සාමාන්‍ය', '❓ ප්‍රශ්න', '💡 උපදෙස්', '👩‍⚕️ වින්නඹු උපදෙස්'];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showCommunityRulesModal(BuildContext context, String midwifeName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.diversity_1_rounded, color: Color(0xFFE91E63), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "මාතෘ ප්‍රජා කවයේ මාර්ගෝපදේශ\nCommunity Circle Guidelines",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleItem("🌸", "මෙම සමූහය $midwifeName මහත්මිය සහ ප්‍රදේශයේ ගර්භණී මව්වරුන් සඳහා පමණක් වෙන්වූ සුරක්ෂිත අවකාශයකි."),
            _buildRuleItem("🤝", "එකිනෙකාට ගෞරවයෙන් සහ ආදරයෙන් අදහස් බෙදාගන්න."),
            _buildRuleItem("👩‍⚕️", "හදිසි අවස්ථාවකදී කරුණාකර තිරයේ ඉහළ ඇති SOS බොත්තම හෝ 1990 අමතන්න."),
            _buildRuleItem("💬", "ප්‍රශ්න, ආහාර රටා සහ සතුටුදායක අත්දැකීම් නිදහසේ මෙහි බෙදාගත හැක."),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("තේරුම් ගත්තා (Understood)", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapOrUrl(BuildContext context, String rawUrl) async {
    try {
      String cleanUrl = rawUrl.trim();
      while (cleanUrl.endsWith('.') ||
          cleanUrl.endsWith(',') ||
          cleanUrl.endsWith(')') ||
          cleanUrl.endsWith(']')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }

      final Uri uri = Uri.parse(cleanUrl);
      bool launched = false;

      // 1. External application launch
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      // 2. Default browser / app launch
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      // 3. Geo URI fallback if coordinates exist in query
      if (!launched) {
        final reg = RegExp(r'q=([0-9.-]+),([0-9.-]+)');
        final match = reg.firstMatch(cleanUrl);
        if (match != null) {
          final lat = match.group(1);
          final lng = match.group(2);
          final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
          try {
            launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Maps විවෘත කිරීමට නොහැකි විය")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("දෝෂයකි: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? currentNic = currentUser?.email?.split('@').first;

    if (currentUser == null || currentNic == null) {
      return const Center(
        child: Text("කරුණාකර නැවත Login වන්න / Please login"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mothers')
          .where('nic', whereIn: [
            currentNic,
            currentNic.toUpperCase(),
            currentNic.toLowerCase(),
          ])
          .limit(1)
          .snapshots(),
      builder: (context, motherSnap) {
        if (!motherSnap.hasData || motherSnap.data!.docs.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)));
        }

        final motherDoc = motherSnap.data!.docs.first;
        final motherData = motherDoc.data() as Map<String, dynamic>;
        final String midwifeName = motherData['assignedMidwife'] ?? "Mrs. Priyanka Perera";
        final String motherName = motherData['fullName'] ?? "Mother";
        final String motherAvatar = motherData['profilePic'] ?? 'assets/avatars/avatar1.png';
        final String mohArea = motherData['mohArea'] ?? "MOH Division";

        // Calculate weeks of pregnancy
        DateTime lmpDate = (motherData['lmp'] != null)
            ? (motherData['lmp'] as Timestamp).toDate()
            : DateTime.now().subtract(const Duration(days: 70));
        int weeks = DateTime.now().difference(lmpDate).inDays ~/ 7;
        if (weeks < 1) weeks = 1;
        if (weeks > 42) weeks = 40;

        final String groupId = CommunityChatService.normalizeGroupId(midwifeName);
        _chatService.ensureGroupExists(groupId, midwifeName);

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Group Luminous Header
              _buildHeader(context, midwifeName, mohArea),

              // 2. Category Filter Pills
              _buildFilterBar(),

              // 3. Messages Stream
              Expanded(
                child: StreamBuilder<List<CommunityMessage>>(
                  stream: _chatService.getMessagesStream(groupId),
                  builder: (context, chatSnap) {
                    if (chatSnap.connectionState == ConnectionState.waiting && !chatSnap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)));
                    }

                    List<CommunityMessage> messages = chatSnap.data ?? [];

                    // Filter messages
                    if (_activeFilter != 'සියල්ල') {
                      messages = messages.where((m) {
                        if (_activeFilter == '👩‍⚕️ වින්නඹු උපදෙස්') return m.senderRole == 'midwife';
                        if (_activeFilter == '💬 සාමාන්‍ය') return m.tag == 'සාමාන්‍ය';
                        if (_activeFilter == '❓ ප්‍රශ්න') return m.tag == 'ප්‍රශ්නයක්';
                        if (_activeFilter == '💡 උපදෙස්') return m.tag == 'උපදෙසක්' || m.tag == 'අත්දැකීමක්';
                        return true;
                      }).toList();
                    }

                    if (messages.isEmpty) {
                      return _buildEmptyState(midwifeName);
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg.senderId == currentUser.uid;
                        return _buildMessageBubble(msg, isMe, currentUser.uid, groupId);
                      },
                    );
                  },
                ),
              ),

              // 4. Message Input Composer
              _buildMessageComposer(
                groupId: groupId,
                midwifeName: midwifeName,
                senderId: currentUser.uid,
                senderName: motherName,
                senderAvatar: motherAvatar,
                pregnancyWeek: weeks,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  1. LUMINOUS COMMUNITY HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String midwifeName, String mohArea) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Midwife Group Avatar Stack
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80DEEA), Color(0xFF00ACC1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("👩‍⚕️", style: TextStyle(fontSize: 24)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Group Name & Midwife
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "🌸 මාතෘ ප්‍රජා කවය",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "ONLINE",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "වින්නඹු නිලධාරිනී: $midwifeName • $mohArea",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Guidelines Info Button
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFFE91E63)),
            onPressed: () => _showCommunityRulesModal(context, midwifeName),
            tooltip: "මාර්ගෝපදේශ (Guidelines)",
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  2. FILTER BAR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF4081)])
                      : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.pink.shade100,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  3. MESSAGE BUBBLES
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMessageBubble(
    CommunityMessage msg,
    bool isMe,
    String currentUserId,
    String groupId,
  ) {
    final bool isMidwife = msg.senderRole == 'midwife';
    final bool isLiked = msg.isLikedBy(currentUserId);
    final String timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Left Avatar (if not me)
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: isMidwife ? const Color(0xFFE0F2F1) : const Color(0xFFFFF0F5),
              child: isMidwife
                  ? const Text("👩‍⚕️", style: TextStyle(fontSize: 18))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        msg.senderAvatar,
                        errorBuilder: (_, __, ___) => const Icon(Icons.face, size: 20, color: Color(0xFFE91E63)),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble Container
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isMidwife
                    ? const LinearGradient(
                        colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : isMe
                        ? const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFFFF9FA)],
                          ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: Border.all(
                  color: isMidwife
                      ? const Color(0xFF00897B)
                      : isMe
                          ? Colors.transparent
                          : Colors.pink.shade100,
                  width: isMidwife ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? const Color(0xFFE91E63) : Colors.black).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Header & Tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sender Name
                      Flexible(
                        child: Text(
                          isMe ? "ඔබ (You)" : msg.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: isMe
                                ? Colors.white
                                : isMidwife
                                    ? const Color(0xFF00695C)
                                    : const Color(0xFF1565C0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Pregnancy Week chip (for mothers)
                      if (!isMidwife && msg.pregnancyWeek != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "සතිය ${msg.pregnancyWeek}",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.white : const Color(0xFFE91E63),
                            ),
                          ),
                        ),
                      ],

                      // Verified Midwife Badge
                      if (isMidwife) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "👩‍⚕️ නිල උපදෙස (Midwife)",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Message Tag pill
                  if (msg.tag != 'සාමාන්‍ය' && !isMidwife)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        msg.tag == 'ප්‍රශ්නයක්'
                            ? "❓ ප්‍රශ්නයක් (Question)"
                            : msg.tag == 'උපදෙසක්'
                                ? "💡 උපදෙසක් (Tip)"
                                : "🌸 ${msg.tag}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : const Color(0xFF5E35B1),
                        ),
                      ),
                    ),

                  // Message Body Text
                  Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Interactive Location / URL Button
                  if (RegExp(r'(https?:\/\/[^\s]+)').hasMatch(msg.message)) ...[
                    const SizedBox(height: 8),
                    () {
                      final url = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(msg.message)?.group(0);
                      if (url == null) return const SizedBox.shrink();
                      final bool isMap = url.contains('maps') || url.contains('google.com/maps') || url.contains('goo.gl');

                      return ElevatedButton.icon(
                        onPressed: () => _openMapOrUrl(context, url),
                        icon: Icon(
                          isMap ? Icons.location_on_rounded : Icons.open_in_new_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          isMap ? "Google Maps හි බලන්න (Open Map)" : "සබැඳිය විවෘත කරන්න",
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMap ? const Color(0xFFD50000) : const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                      );
                    }(),
                  ],
                  const SizedBox(height: 8),

                  // Bottom Row: Time & Like Counter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Heart / Like Button
                      GestureDetector(
                        onTap: () => _chatService.toggleLike(
                          groupId: groupId,
                          messageId: msg.id,
                          userId: currentUserId,
                          isCurrentlyLiked: isLiked,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLiked
                                ? (isMe
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : const Color(0xFFFFEBEE))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 14,
                                color: isLiked
                                    ? (isMe ? Colors.white : const Color(0xFFE91E63))
                                    : (isMe ? Colors.white70 : Colors.grey.shade400),
                              ),
                              if (msg.likes.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "${msg.likes.length}",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isLiked
                                        ? (isMe ? Colors.white : const Color(0xFFE91E63))
                                        : (isMe ? Colors.white70 : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right Avatar (if me)
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFF0F5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  msg.senderAvatar,
                  errorBuilder: (_, __, ___) => const Icon(Icons.face, size: 20, color: Color(0xFFE91E63)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  4. EMPTY STATE
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(String midwifeName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_rounded, color: Color(0xFFE91E63), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              "ප්‍රජා කවයට සාදරයෙන් පිළිගනිමු! 🌸",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 6),
            Text(
              "$midwifeName මහත්මිය සහ ප්‍රදේශයේ මව්වරුන් සමඟ අදහස් හුවමාරු කර ගැනීමට පළමු පණිවිඩය මෙතැනින් එක් කරන්න.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  5. MESSAGE COMPOSER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMessageComposer({
    required String groupId,
    required String midwifeName,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required int pregnancyWeek,
  }) {
    // Check if on-screen keyboard is open
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    // When keyboard is open, dock directly above keyboard (8px); when closed in tab, dock above nav bar (68px)
    final double bottomInset = isKeyboardOpen ? 8.0 : (widget.isTab ? 68.0 : 8.0);

    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Tag Selector Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTag = tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        tag == 'සාමාන්‍ය'
                            ? "💬 සාමාන්‍ය (General)"
                            : tag == 'ප්‍රශ්නයක්'
                                ? "❓ ප්‍රශ්නයක් (Question)"
                                : tag == 'උපදෙසක්'
                                    ? "💡 උපදෙසක් (Tip)"
                                    : "🌸 $tag",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Text Field & Send Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.pink.shade50, width: 1.2),
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "ඔබේ අදහස හෝ ප්‍රශ්නය ලියන්න...",
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Button
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _isSending
                      ? null
                      : () async {
                          final text = _textController.text.trim();
                          if (text.isEmpty) return;

                          setState(() => _isSending = true);
                          _textController.clear();

                          try {
                            await _chatService.sendMessage(
                              groupId: groupId,
                              midwifeName: midwifeName,
                              senderId: senderId,
                              senderName: senderName,
                              senderRole: 'mother',
                              senderAvatar: senderAvatar,
                              pregnancyWeek: pregnancyWeek,
                              message: text,
                              tag: _selectedTag,
                            );

                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("දෝෂයකි: $e")),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSending = false);
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
