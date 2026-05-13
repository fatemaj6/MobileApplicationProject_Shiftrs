import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserProfile?> getProfile() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateProfile(UserProfile profile) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    if (uid != profile.id) throw Exception('Cannot update another user profile');

    await _firestore.collection('users').doc(uid).set(profile.toJson(), SetOptions(merge: true));
  }

  Future<String> uploadProfilePhoto(File imageFile) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    // Automatically update the Firestore doc with the new photo URL
    await _firestore.collection('users').doc(uid).set({'photoUrl': downloadUrl}, SetOptions(merge: true));

    return downloadUrl;
  }
}
