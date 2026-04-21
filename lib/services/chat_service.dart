import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get chats => _firestore.collection('chats');

  // Create or get existing chat
  Future<String> getOrCreateChat({
    required String otherUserId,
    required String bookId,
    required String bookTitle,
  }) async {
    String currentUserId = _auth.currentUser!.uid;

    // Check if chat already exists
    QuerySnapshot existingChat = await chats
        .where('participants', arrayContains: currentUserId)
        .where('bookId', isEqualTo: bookId)
        .get();

    if (existingChat.docs.isNotEmpty) {
      return existingChat.docs.first.id;
    }

    // Create new chat
    String chatId = _firestore.collection('chats').doc().id;
    ChatModel newChat = ChatModel(
      id: chatId,
      participants: [currentUserId, otherUserId],
      bookId: bookId,
      bookTitle: bookTitle,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: {currentUserId: 0, otherUserId: 0},
    );

    await chats.doc(chatId).set(newChat.toMap());
    return chatId;
  }

  // Get user's chats
  Stream<QuerySnapshot> getUserChats() {
    String currentUserId = _auth.currentUser!.uid;
    return chats
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get messages for a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    String currentUserId = _auth.currentUser!.uid;

    // Get chat participants
    DocumentSnapshot chatDoc = await chats.doc(chatId).get();
    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
    List<String> participants = List<String>.from(chatData['participants']);

    // Find other user
    String otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
    );

    // Add message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': DateTime.now(),
      'isRead': false,
    });

    // Update chat last message
    Map<String, int> unreadCount = Map<String, int>.from(chatData['unreadCount'] ?? {});
    unreadCount[otherUserId] = (unreadCount[otherUserId] ?? 0) + 1;

    await chats.doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': DateTime.now(),
      'unreadCount': unreadCount,
    });
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    String currentUserId = _auth.currentUser!.uid;

    DocumentSnapshot chatDoc = await chats.doc(chatId).get();
    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
    Map<String, int> unreadCount = Map<String, int>.from(chatData['unreadCount'] ?? {});
    unreadCount[currentUserId] = 0;

    await chats.doc(chatId).update({'unreadCount': unreadCount});

    // Mark all messages as read
    QuerySnapshot unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // React to a message
  Future<void> reactToMessage({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference messageRef = chats.doc(chatId).collection('messages').doc(messageId);

    DocumentSnapshot messageDoc = await messageRef.get();
    Map<String, dynamic> data = messageDoc.data() as Map<String, dynamic>;
    Map<String, String> reactions = Map<String, String>.from(data['reactions'] ?? {});

    if (reactions[currentUserId] == emoji) {
      reactions.remove(currentUserId); // Toggle off if same emoji
    } else {
      reactions[currentUserId] = emoji; // Add/Change emoji
    }

    await messageRef.update({'reactions': reactions});
  }

  // Delete message for me
  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
  }) async {
    String currentUserId = _auth.currentUser!.uid;
    await chats.doc(chatId).collection('messages').doc(messageId).update({
      'deletedBy': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // Unsend message for everyone
  Future<void> unsendMessage({
    required String chatId,
    required String messageId,
  }) async {
    await chats.doc(chatId).collection('messages').doc(messageId).update({
      'isUnsent': true,
      'text': '', // Clear text for security/privacy
      'reactions': {}, // Clear reactions
    });
  }
}
