// lib/controller/signup_controller.dart

import 'package:firebase_auth/firebase_auth.dart';

class SignupController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to handle sign in
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      // Handle errors (e.g., wrong credentials, network issues)
      print('Error during sign-in: $e');
      return null;
    }
  }

  // Method to handle sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
