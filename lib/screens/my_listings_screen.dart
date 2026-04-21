import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/book_model.dart';
import '../utils/helpers.dart';
import '../widgets/loading_widget.dart';

class MyListingsScreen extends StatelessWidget {
  MyListingsScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _deleteBook(BuildContext context, String bookId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this book listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteBook(bookId);
      if (context.mounted) Helpers.showToast('Book listing deleted');
    }
  }

  Future<void> _markAsExchanged(BuildContext context, String bookId) async {
    await _firestoreService.updateBookStatus(bookId, 'Exchanged');
    if (context.mounted) Helpers.showToast('Book marked as exchanged');
  }

  Future<void> _markAsSold(BuildContext context, String bookId) async {
    await _firestoreService.updateBookStatus(bookId, 'Sold');
    if (context.mounted) Helpers.showToast('Book marked as sold');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserBooks(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const LoadingWidget();
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No books listed yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first book', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var book = BookModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(book.author, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(book.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(book.status, style: TextStyle(color: _getStatusColor(book.status), fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(Helpers.formatPrice(book.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (book.status == 'Available') ...[
                            if (book.exchangePreference == 'Sell' || book.exchangePreference == 'Both')
                              _buildActionButton(Icons.attach_money, 'Sold', Colors.green, () => _markAsSold(context, book.id)),
                            if (book.exchangePreference == 'Exchange' || book.exchangePreference == 'Both')
                              _buildActionButton(Icons.swap_horiz, 'Exchanged', Colors.orange, () => _markAsExchanged(context, book.id)),
                          ],
                          _buildActionButton(Icons.delete, 'Delete', Colors.red, () => _deleteBook(context, book.id)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Pending': return Colors.orange;
      case 'Exchanged': return Colors.blue;
      case 'Sold': return Colors.grey;
      default: return Colors.grey;
    }
  }
}