import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/firestore_service.dart';
import '../services/chat_service.dart';
import '../services/friend_service.dart';
import '../models/book_model.dart';
import '../models/request_model.dart';
import '../utils/helpers.dart';
import '../widgets/loading_widget.dart';
import 'chat_screen.dart';
import '../widgets/rating_dialog.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  final FriendService _friendService = FriendService();
  late Future<BookModel?> _bookFuture;
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isRequesting = false;
  String _friendStatus = 'none'; // 'none', 'sent', 'received', 'friends'

  @override
  void initState() {
    super.initState();
    _bookFuture = _firestoreService.getBook(widget.bookId).then((book) {
      if (book != null && book.sellerId != currentUserId) {
        _checkFriendStatus(book.sellerId);
      }
      return book;
    });
  }

  Future<void> _checkFriendStatus(String sellerId) async {
    final status = await _friendService.getRelationshipStatus(sellerId);
    if (mounted) setState(() => _friendStatus = status);
  }

  Future<void> _sendFriendRequest(BookModel book) async {
    await _friendService.sendFriendRequest(book.sellerId, book.sellerName);
    _checkFriendStatus(book.sellerId);
    Helpers.showToast('Friend request sent!');
  }

  Future<void> _sendRequest(BookModel book, String? offeredBookId) async {
    setState(() => _isRequesting = true);

    try {
      String requestId = DateTime.now().millisecondsSinceEpoch.toString();

      RequestModel request = RequestModel(
        id: requestId,
        bookId: book.id,
        requesterId: currentUserId,
        sellerId: book.sellerId,
        message: 'I am interested in this book',
        offeredBookId: offeredBookId,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createRequest(request);

      // Create chat for negotiation
      await _chatService.getOrCreateChat(
        otherUserId: book.sellerId,
        bookId: book.id,
        bookTitle: book.title,
      );

      if (mounted) {
        Helpers.showToast('Request sent to seller!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Helpers.showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _showRequestDialog(BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Book: ${book.title}'),
            const SizedBox(height: 8),
            Text('Seller: ${book.sellerName}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            if (book.exchangePreference == 'Exchange' || book.exchangePreference == 'Both')
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Your book to exchange (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendRequest(book, null);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _startChat(BookModel book) async {
    String chatId = await _chatService.getOrCreateChat(
      otherUserId: book.sellerId,
      bookId: book.id,
      bookTitle: book.title,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            bookTitle: book.title,
            otherUserId: book.sellerId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<BookModel?>(
        future: _bookFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const LoadingWidget(isList: false);
          }
          if (snapshot.data == null) {
            return const Center(child: Text('Book not found'));
          }

          final book = snapshot.data!;
          bool isMyBook = book.sellerId == currentUserId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.teal.shade800, Colors.teal.shade500],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.book, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by ${book.author}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Condition & Category Row
                      Row(
                        children: [
                          _buildInfoChip(
                              '${Helpers.getConditionIcon(book.conditionRating)} Book Rating',
                              Helpers.getConditionColor(book.conditionRating)),
                          const SizedBox(width: 8),
                          RatingBarIndicator(
                            rating: book.conditionRating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 18.0,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(book.category, Colors.purple),
                          const SizedBox(width: 8),
                          _buildInfoChip(book.exchangePreference, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Price
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money, size: 30, color: Colors.green),
                            Text(
                              Helpers.formatPrice(book.price),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Wanted Book (if exchange)
                      if (book.wantedBookTitle != null && book.wantedBookTitle!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Wants: ${book.wantedBookTitle}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Description
                      const Text('Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(book.description.isNotEmpty
                          ? book.description
                          : 'No description provided'),
                      const SizedBox(height: 16),
                      // Seller Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(Icons.person, color: Colors.teal),
                            ),                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book.sellerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      RatingBarIndicator(
                                        rating: book.sellerRating,
                                        itemBuilder: (context, index) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 16.0,
                                        direction: Axis.horizontal,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        book.sellerRating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (book.sellerId != currentUserId)
                              _buildFriendButton(book),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                if (!isMyBook && book.status == 'Available')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, -2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isRequesting ? null : () => _startChat(book),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.teal.shade700),
                            ),
                            child: const Text('Chat with Seller'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isRequesting ? null : () => _showRequestDialog(book),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Send Request'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isMyBook)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'This is your listing',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (book.status != 'Available')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'This book is ${book.status.toLowerCase()}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
  Future<void> _submitRating(double rating, String sellerId) async {
    await _firestoreService.updateUserRating(sellerId, rating);
    Helpers.showToast('Thank you for rating!');
    // Refresh to update the star display if needed
    setState(() {
      _bookFuture = _firestoreService.getBook(widget.bookId);
    });
  }

  Widget _buildFriendButton(BookModel book) {
    if (_friendStatus == 'friends') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.star_outline_rounded, color: Colors.amber),
            tooltip: 'Rate Seller',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => RatingDialog(
                userId: book.sellerId,
                userName: book.sellerName,
                onRatingSubmit: (rating) => _submitRating(rating, book.sellerId),
              ),
            ),
          ),
          const Icon(Icons.people, color: Colors.teal),
        ],
      );
    }
    if (_friendStatus == 'sent') {
      return const Icon(Icons.hourglass_empty, color: Colors.grey);
    }
    if (_friendStatus == 'received') {
      return IconButton(
        icon: const Icon(Icons.person_add, color: Colors.orange),
        onPressed: () => Helpers.showToast('Go to Profile to accept request'),
      );
    }
    return IconButton(
      icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.teal),
      onPressed: () => _sendFriendRequest(book),
    );
  }
}