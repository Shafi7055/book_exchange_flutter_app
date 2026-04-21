import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime timestamp;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory FriendRequestModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedTime;
    var rawTimestamp = map['timestamp'];
    
    if (rawTimestamp == null || rawTimestamp is! Timestamp) {
      parsedTime = DateTime.now(); // Fallback for local cache/fieldvalue
    } else {
      parsedTime = rawTimestamp.toDate();
    }

    return FriendRequestModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: parsedTime,
    );
  }
}
