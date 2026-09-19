import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_message.dart';

class CommunityChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sanitizes midwife name into a unified group ID matching both apps
  static String normalizeGroupId(String midwifeName) {
    if (midwifeName.trim().isEmpty) return "midwife_group_priyanka_perera";
    
    // Remove honorifics/prefixes: mrs, ms, miss, dr, phm, sister
    String cleaned = midwifeName.trim().toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'^(mrs\.|mrs|ms\.|ms|miss\.|miss|dr\.|dr|phm\.|phm|sister)\s*', caseSensitive: false), '');
    
    // Replace non-alphanumeric characters with single underscore
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'_+'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    
    if (cleaned.isEmpty) return "midwife_group_priyanka_perera";
    return "midwife_group_$cleaned";
  }

  /// Ensures group document metadata is maintained
  Future<void> ensureGroupExists(String groupId, String midwifeName) async {
    final groupRef = _db.collection('community_groups').doc(groupId);
    final doc = await groupRef.get();
    if (!doc.exists) {
      await groupRef.set({
        'groupId': groupId,
        'midwifeName': midwifeName,
        'title': "🌸 $midwifeName's Maternal Circle",
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': "සාදරයෙන් පිළිගනිමු! (Welcome to the maternal circle!)",
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Sends a new message to the group
  Future<void> sendMessage({
    required String groupId,
    required String midwifeName,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String senderAvatar,
    int? pregnancyWeek,
    required String message,
    String tag = 'සාමාන්‍ය',
  }) async {
    if (message.trim().isEmpty) return;

    final groupRef = _db.collection('community_groups').doc(groupId);
    final messagesRef = groupRef.collection('messages');

    // Add message
    await messagesRef.add({
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderAvatar': senderAvatar,
      'pregnancyWeek': pregnancyWeek,
      'message': message.trim(),
      'tag': tag,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });

    // Update group latest message
    await groupRef.set({
      'groupId': groupId,
      'midwifeName': midwifeName,
      'lastMessage': message.trim(),
      'lastMessageSender': senderName,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream of real-time messages
  Stream<List<CommunityMessage>> getMessagesStream(String groupId) {
    return _db
        .collection('community_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMessage.fromFirestore(doc))
            .toList());
  }

  /// Toggle like/heart on a message
  Future<void> toggleLike({
    required String groupId,
    required String messageId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    final msgRef = _db
        .collection('community_groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId);

    if (isCurrentlyLiked) {
      await msgRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await msgRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }
}
