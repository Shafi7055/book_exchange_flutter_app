class ChatModel {
  String id;
  List<String> participants;
  String bookId;
  String bookTitle;
  String lastMessage;
  DateTime lastMessageTime;
  Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    required this.participants,
    required this.bookId,
    required this.bookTitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as dynamic).toDate(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }
}

class MessageModel {
  String id;
  String senderId;
  String text;
  DateTime timestamp;
  bool isRead;
  Map<String, String> reactions; // userId -> emoji
  List<String> deletedBy; // list of userIds who deleted for themselves
  bool isUnsent;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.reactions = const {},
    this.deletedBy = const [],
    this.isUnsent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'reactions': reactions,
      'deletedBy': deletedBy,
      'isUnsent': isUnsent,
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as dynamic).toDate(),
      isRead: map['isRead'] ?? false,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
      isUnsent: map['isUnsent'] ?? false,
    );
  }
}