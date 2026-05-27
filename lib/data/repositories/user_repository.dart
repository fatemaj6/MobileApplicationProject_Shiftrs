import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  Future<String?> findCaregiverUidByEmail(String caregiverEmail) async {
  final query = await _db
      .collection('users')
      .where('email', isEqualTo: caregiverEmail.trim())
      .limit(1)
      .get();

  if (query.docs.isEmpty) return null;

  final data = query.docs.first.data();
  final role = data['role']?.toString().toLowerCase().trim();

  if (role != 'caregiver') return null;

  return query.docs.first.id;
}

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? linkedCaregiverId,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),

      if (role == 'family' && linkedCaregiverId != null)
        'linkedCaregiverId': linkedCaregiverId,
    });
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }
}