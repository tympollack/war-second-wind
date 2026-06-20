import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

// ── FIREBASE SWAP-IN ────────────────────────────────────────────────────────
// 1. Add to pubspec.yaml:
//      firebase_core: ^3.0.0
//      firebase_auth: ^5.0.0
//      google_sign_in: ^6.0.0
//
// 2. Replace this entire file with the Firebase-backed version below:
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class AuthService extends ChangeNotifier {
//   final _auth = FirebaseAuth.instance;
//   UserModel? _user;
//   UserModel? get currentUser => _user;
//   bool get isLoggedIn => _user != null;
//
//   AuthService() {
//     _auth.authStateChanges().listen((User? u) {
//       _user = u != null ? UserModel.fromFirebase(u) : null;
//       notifyListeners();
//     });
//   }
//
//   Future<String?> signIn({required String email, required String password}) async {
//     try {
//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return null;
//     } on FirebaseAuthException catch (e) { return e.message; }
//   }
//
//   Future<String?> signUp({required String email, required String password, required String displayName}) async {
//     try {
//       final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
//       await cred.user?.updateDisplayName(displayName);
//       return null;
//     } on FirebaseAuthException catch (e) { return e.message; }
//   }
//
//   Future<String?> signInWithGoogle() async {
//     try {
//       final gUser = await GoogleSignIn().signIn();
//       if (gUser == null) return 'Cancelled';
//       final gAuth = await gUser.authentication;
//       final cred  = GoogleAuthProvider.credential(
//         accessToken: gAuth.accessToken, idToken: gAuth.idToken);
//       await _auth.signInWithCredential(cred);
//       return null;
//     } on FirebaseAuthException catch (e) { return e.message; }
//   }
//
//   Future<void> signOut() => _auth.signOut();
//
//   Future<String?> resetPassword(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email);
//       return null;
//     } on FirebaseAuthException catch (e) { return e.message; }
//   }
//
//   Future<String?> updateDisplayName(String name) async {
//     try {
//       await _auth.currentUser?.updateDisplayName(name);
//       _user = _user?.copyWith(displayName: name);
//       notifyListeners();
//       return null;
//     } on FirebaseAuthException catch (e) { return e.message; }
//   }
//
//   Future<String?> deleteAccount() async {
//     try {
//       await _auth.currentUser?.delete();
//       return null;
//     } on FirebaseAuthException catch (e) { return e.message; }
//   }
// }
// ────────────────────────────────────────────────────────────────────────────

enum AuthStatus { checking, loggedIn, loggedOut }

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.loggedOut;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status      => _status;
  bool       get isLoggedIn  => _status == AuthStatus.loggedIn;

  // Simulated in-memory user store
  final Map<String, ({String password, String displayName})> _mockDb = {};

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (email.isEmpty || password.isEmpty) return 'Please fill in all fields.';

    final stored = _mockDb[email.toLowerCase()];
    if (stored == null) return 'No account found for that email.';
    if (stored.password != password) return 'Incorrect password.';

    _currentUser = UserModel(
      id:          email.toLowerCase().hashCode.toString(),
      email:       email,
      displayName: stored.displayName,
      createdAt:   DateTime.now(),
    );
    _status = AuthStatus.loggedIn;
    notifyListeners();
    return null; // null = success
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      return 'Please fill in all fields.';
    }
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (_mockDb.containsKey(email.toLowerCase())) {
      return 'An account with this email already exists.';
    }

    _mockDb[email.toLowerCase()] = (
      password:    password,
      displayName: displayName,
    );
    _currentUser = UserModel(
      id:          email.toLowerCase().hashCode.toString(),
      email:       email,
      displayName: displayName,
      createdAt:   DateTime.now(),
    );
    _status = AuthStatus.loggedIn;
    notifyListeners();
    return null;
  }

  // ── Google Sign In (stub) ─────────────────────────────────────────────────
  Future<String?> signInWithGoogle() async {
    // FIREBASE: Replace with Google Sign-In flow (see comment at top of file).
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = const UserModel(
      id:          'google-demo-uid',
      email:       'demo@gmail.com',
      displayName: 'Demo Player',
    );
    _status = AuthStatus.loggedIn;
    notifyListeners();
    return null;
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<String?> resetPassword(String email) async {
    // FIREBASE: await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!_mockDb.containsKey(email.toLowerCase())) {
      return 'No account found for that email.';
    }
    return null; // Mock: pretend the email was sent
  }

  // ── Update Display Name ───────────────────────────────────────────────────
  Future<String?> updateDisplayName(String name) async {
    // FIREBASE: await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    await Future.delayed(const Duration(milliseconds: 500));
    if (name.trim().isEmpty) return 'Name cannot be empty.';
    _currentUser = _currentUser?.copyWith(displayName: name.trim());
    notifyListeners();
    return null;
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    // FIREBASE: await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

  // ── Delete Account ────────────────────────────────────────────────────────
  Future<String?> deleteAccount() async {
    // FIREBASE: await FirebaseAuth.instance.currentUser?.delete();
    await Future.delayed(const Duration(milliseconds: 600));
    if (_currentUser != null) {
      _mockDb.remove(_currentUser!.email.toLowerCase());
    }
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
    return null;
  }
}