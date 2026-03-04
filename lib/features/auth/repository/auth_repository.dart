import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/log/app_log.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    appLog('Signed in: ${credential.user?.email}', source: 'AuthRepo');
    return credential.user;
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // Update display name
    await user.updateDisplayName(name);

    // Create user document in Firestore
    await _createUserDocument(user: user, name: name);

    appLog('Signed up: ${user.email}', source: 'AuthRepo');
    return user;
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    appLog('Signed out', source: 'AuthRepo');
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  // Create user document in Firestore on first sign up
  Future<void> _createUserDocument({
    required User user,
    required String name,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    // Only create if not already exists (avoid overwriting on re-login)
    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
