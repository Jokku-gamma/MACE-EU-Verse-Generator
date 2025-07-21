import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'Login failed: ${e.message}';
      }
      throw errorMessage; // Throw a user-friendly message
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // You might add methods here for registration if you implement it later
  // Future<UserCredential> registerWithEmailAndPassword(String email, String password) async { ... }
}