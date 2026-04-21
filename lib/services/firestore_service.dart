import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get books => _firestore.collection('books');
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get requests => _firestore.collection('requests');

  // Add a book
  Future<void> addBook(BookModel book) async {
    await books.doc(book.id).set(book.toMap());
  }

  // Get all available books
  Stream<QuerySnapshot> getAvailableBooks() {
    return books
        .where('status', isEqualTo: 'Available')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get books by category
  Stream<QuerySnapshot> getBooksByCategory(String category) {
    return books
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'Available')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get books by user
  Stream<QuerySnapshot> getUserBooks(String userId) {
    return books
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get single book
  Future<BookModel?> getBook(String bookId) async {
    DocumentSnapshot doc = await books.doc(bookId).get();
    if (doc.exists) {
      return BookModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Update book status
  Future<void> updateBookStatus(String bookId, String status) async {
    await books.doc(bookId).update({'status': status});
  }

  // Delete book
  Future<void> deleteBook(String bookId) async {
    await books.doc(bookId).delete();
  }

  // Search books
  Stream<QuerySnapshot> searchBooks(String query) {
    return books
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .where('status', isEqualTo: 'Available')
        .snapshots();
  }

  // Create a request
  Future<void> createRequest(RequestModel request) async {
    await requests.doc(request.id).set(request.toMap());
  }

  // Get requests for seller
  Stream<QuerySnapshot> getSellerRequests(String sellerId) {
    return requests
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get requests by requester
  Stream<QuerySnapshot> getRequesterRequests(String requesterId) {
    return requests
        .where('requesterId', isEqualTo: requesterId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    await requests.doc(requestId).update({
      'status': status,
      'respondedAt': DateTime.now(),
    });
  }

  // Get user by ID
  Future<DocumentSnapshot> getUser(String userId) async {
    return await users.doc(userId).get();
  }

  // Admin: Get all books stream
  Stream<QuerySnapshot> getAllBooks() {
    return books.orderBy('createdAt', descending: true).snapshots();
  }

  // Admin: Get all requests stream
  Stream<QuerySnapshot> getAllRequests() {
    return requests.orderBy('createdAt', descending: true).snapshots();
  }

  // Admin: Get all users stream
  Stream<QuerySnapshot> getAllUsers() {
    return users.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE USER RATING
  Future<void> updateUserRating(String userId, double newRating) async {
    final userDoc = await users.doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    double currentRating = (data['rating'] ?? 0.0).toDouble();
    int totalExchanges = data['totalExchanges'] ?? 0;

    // Calculate new average rating
    // Formula: ((Current Rating * Total Exchanges) + New Rating) / (Total Exchanges + 1)
    double updatedRating = ((currentRating * totalExchanges) + newRating) / (totalExchanges + 1);

    await users.doc(userId).update({
      'rating': updatedRating,
      'totalExchanges': totalExchanges + 1,
    });
  }
}