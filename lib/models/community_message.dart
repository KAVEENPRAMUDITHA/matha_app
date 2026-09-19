import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'mother' or 'midwife'
  final String senderAvatar;
  final int? pregnancyWeek;
  final String message;
  final String tag; // 'සාමාන්‍ය', 'ප්‍රශ්නයක්', 'උපදෙසක්', 'නිල නිවේදනය'
  final DateTime timestamp;
  final List<String> likes;

  CommunityMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.senderAvatar,
    this.pregnancyWeek,
    required this.message,
    required this.tag,
    required this.timestamp,
    required this.likes,
  });

  factory CommunityMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonymous',
      senderRole: data['senderRole'] ?? 'mother',
      senderAvatar: data['senderAvatar'] ?? 'assets/avatars/avatar1.png',
      pregnancyWeek: data['pregnancyWeek'] is int ? data['pregnancyWeek'] : null,
      message: data['message'] ?? '',
      tag: data['tag'] ?? 'සාමාන්‍ය',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderAvatar': senderAvatar,
      'pregnancyWeek': pregnancyWeek,
      'message': message,
      'tag': tag,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
    };
  }

  bool isLikedBy(String userId) => likes.contains(userId);
}
