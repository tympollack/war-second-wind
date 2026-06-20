// ── FIREBASE SETUP ──────────────────────────────────────────────────────────
// 1. Run: flutter pub add firebase_core firebase_auth cloud_firestore google_sign_in
// 2. Follow FlutterFire CLI setup: flutterfire configure
// 3. Replace all "// FIREBASE:" comments below with real implementation
// ────────────────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  /// Two-letter initials for avatar display.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  UserModel copyWith({String? displayName, String? photoUrl}) => UserModel(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] as String,
        email: m['email'] as String,
        displayName: m['displayName'] as String,
        photoUrl: m['photoUrl'] as String?,
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt'] as String)
            : null,
      );

  // FIREBASE: Replace mock user with:
  // import 'package:firebase_auth/firebase_auth.dart';
  // factory UserModel.fromFirebase(User u) => UserModel(
  //   id:          u.uid,
  //   email:       u.email ?? '',
  //   displayName: u.displayName ?? u.email?.split('@').first ?? 'Player',
  //   photoUrl:    u.photoURL,
  //   createdAt:   u.metadata.creationTime,
  // );
}