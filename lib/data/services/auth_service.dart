import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        default:
          return 'Registration failed. Please try again.';
      }
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        default:
          return 'Login failed. Please try again.';
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
