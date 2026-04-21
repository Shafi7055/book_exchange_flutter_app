import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadBookImage(File image, String bookId) async {
    Reference ref = _storage
        .ref()
        .child('books/$bookId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleImages(List<File> images, String bookId) async {
    List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      String url = await uploadBookImage(images[i], bookId);
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadProfileImage(File image) async {
    String userId = _auth.currentUser!.uid;
    Reference ref = _storage.ref().child('profiles/$userId.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      await deleteImage(url);
    }
  }
}