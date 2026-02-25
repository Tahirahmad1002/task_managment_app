import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This is the line your main.dart is looking for!
  // It listens to whether a user is logged in or out automatically.
  Stream<User?> get user => _auth.authStateChanges();

  // 1. SIGN UP
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 2. LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 3. RESET PASSWORD
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Success"; // This means the email was sent!
    } on FirebaseAuthException catch (e) {
      return e.message; // Returns error like "User not found" or "Invalid email"
    }
  }

  // 4. LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}