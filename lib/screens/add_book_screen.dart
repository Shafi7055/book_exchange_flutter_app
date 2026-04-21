import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/book_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/loading_widget.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _editionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _wantedBookController = TextEditingController();

  double _conditionRating = 3.0;
  String _exchangePreference = 'Sell';
  String _category = 'Other';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exchangePreference != 'Sell' && _wantedBookController.text.isEmpty) {
      Helpers.showToast('Please enter the book you want in exchange');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      var userData = await _firestoreService.getUser(userId);
      String userName = 'User';
      double userRating = 0.0;

      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>?;
        userName = data?['name'] ?? 'User';
        userRating = (data?['rating'] ?? 0.0).toDouble();
      }

      String bookId = DateTime.now().millisecondsSinceEpoch.toString();

      BookModel newBook = BookModel(
        id: bookId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        edition: _editionController.text.trim(),
        conditionRating: _conditionRating,
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        exchangePreference: _exchangePreference,
        wantedBookTitle: _exchangePreference != 'Sell' ? _wantedBookController.text.trim() : null,
        images: [],
        sellerId: userId,
        sellerName: userName,
        sellerRating: userRating,
        status: 'Available',
        createdAt: DateTime.now(),
        category: _category,
      );

      await _firestoreService.addBook(newBook);
      Helpers.showToast('Book listed successfully!');

      _clearForm();
    } catch (e) {
      Helpers.showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _editionController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _wantedBookController.clear();
    setState(() {
      _conditionRating = 3.0;
      _exchangePreference = 'Sell';
      _category = 'Other';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add Book'),
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Book Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Book Title', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Author
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Edition
                  TextFormField(
                    controller: _editionController,
                    decoration: const InputDecoration(labelText: 'Edition (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // Book Condition Rating
                  const Text('Book Condition Rating (Owner Rating)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: 3,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _conditionRating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 12),

                  // Exchange Preference
                  DropdownButtonFormField(
                    value: _exchangePreference,
                    decoration: const InputDecoration(labelText: 'Exchange Preference', border: OutlineInputBorder()),
                    items: AppConstants.exchangePreferences.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _exchangePreference = v!),
                  ),
                  const SizedBox(height: 12),

                  // Price (if Sell or Both)
                  if (_exchangePreference != 'Exchange')
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()),
                    ),

                  // Wanted Book (if Exchange or Both)
                  if (_exchangePreference != 'Sell') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wantedBookController,
                      decoration: const InputDecoration(labelText: 'Wanted Book', border: OutlineInputBorder()),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                      child: const Text('List Book', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        //if (_isLoading) const LoadingOverlay(isLoading: true),
        if (_isLoading) const LoadingOverlay(child: SizedBox.shrink(), isLoading: true),      ],
    );
  }
}