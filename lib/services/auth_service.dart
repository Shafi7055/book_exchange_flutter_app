import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ADD THIS LINE ↓↓↓↓↓
  Stream<User?> get currentUserChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

    if (doc.exists) {
      return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String collegeName,
    required String department,
    required int semester,
    required String phoneNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      String role = (email.trim().toLowerCase() == 'muhammed.mihsshafi05@gmail.com') 
          ? 'admin' 
          : 'user';

      UserModel newUser = UserModel(
        uid: result.user!.uid,
        name: name,
        nickname: nickname,
        email: email.trim(),
        collegeName: collegeName,
        department: department,
        semester: semester,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        role: role,
      );

      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? name,
    String? nickname,
    String? phoneNumber,
    String? profileImage,
  }) async {
    if (_auth.currentUser == null) return;

    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (nickname != null) updates['nickname'] = nickname;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (profileImage != null) updates['profileImage'] = profileImage;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update(updates);
    notifyListeners();
  }
}