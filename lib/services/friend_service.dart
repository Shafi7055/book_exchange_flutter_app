import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _requests => _firestore.collection('friend_requests');
  CollectionReference get _users => _firestore.collection('users');

  // Send request
  Future<void> sendFriendRequest(String targetUserId, String targetUserName) async {
    final currentUserId = _auth.currentUser!.uid;
    
    // Get current user name for the request
    final currentUserDoc = await _users.doc(currentUserId).get();
    final currentUserName = currentUserDoc['nickname'] ?? (currentUserDoc['name'] ?? 'User');

    final requestId = '${currentUserId}_${targetUserId}';
    
    await _requests.doc(requestId).set({
      'senderId': currentUserId,
      'senderName': currentUserName,
      'receiverId': targetUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Accept request
  Future<void> acceptFriendRequest(String requestId, String senderId, String receiverId) async {
    // 1. Update request status
    await _requests.doc(requestId).update({'status': 'accepted'});

    // 2. Add to sender's friend list (Safely ensure field exists)
    await _users.doc(senderId).set({
      'friends': FieldValue.arrayUnion([receiverId])
    }, SetOptions(merge: true));

    // 3. Add to receiver's friend list (Safely ensure field exists)
    await _users.doc(receiverId).set({
      'friends': FieldValue.arrayUnion([senderId])
    }, SetOptions(merge: true));
  }

  // Reject / Ignore request
  Future<void> ignoreFriendRequest(String requestId) async {
    await _requests.doc(requestId).delete();
  }

  // Stream of pending requests
  Stream<List<FriendRequestModel>> getPendingRequests() {
    return _requests
        .where('receiverId', isEqualTo: _auth.currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Stream of sent requests
  Stream<List<FriendRequestModel>> getSentRequests() {
    return _requests
        .where('senderId', isEqualTo: _auth.currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Stream of friends
  Stream<List<UserModel>> getFriends() {
    return _users.doc(_auth.currentUser!.uid).snapshots().asyncMap((snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return [];
      
      final friendIds = List<String>.from(data['friends'] ?? []);
      if (friendIds.isEmpty) return [];
      
      // Batch fetch users. Note: whereIn is limited to 10/30 items depending on Firestore.
      // For a student project, this is usually sufficient.
      final friendDocs = await _users.where(FieldPath.documentId, whereIn: friendIds).get();
      return friendDocs.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Check relationship status
  Future<String> getRelationshipStatus(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    
    // Check if friends
    final userDoc = await _users.doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final friends = List<String>.from(userData?['friends'] ?? []);
    if (friends.contains(otherUserId)) return 'friends';

    // Check if sent request
    final sentRequest = await _requests.doc('${currentUserId}_${otherUserId}').get();
    if (sentRequest.exists && sentRequest['status'] == 'pending') return 'sent';

    // Check if received request
    final receivedRequest = await _requests.doc('${otherUserId}_${currentUserId}').get();
    if (receivedRequest.exists && receivedRequest['status'] == 'pending') return 'received';

    return 'none';
  }
}
