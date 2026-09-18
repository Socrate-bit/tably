import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/user_profile.dart';

/// Reads and writes the user document at `users/{uid}`.
class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('users').doc(uid);

  /// Live profile. Emits null while the document does not exist yet.
  Stream<UserProfile?> watch(String uid) => _doc(uid).snapshots().map((snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return UserProfile.fromMap(data);
      }).handleError((Object e) {
        debugPrint('[ProfileService] watch failed: $e');
      });

  /// Writes the whole profile, creating the document if needed.
  Future<void> save(String uid, UserProfile profile) async {
    try {
      await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
      debugPrint('[ProfileService] saved profile for $uid');
    } catch (e) {
      debugPrint('[ProfileService] save failed: $e');
      rethrow;
    }
  }

  Future<UserProfile?> fetch(String uid) async {
    try {
      final snap = await _doc(uid).get();
      final data = snap.data();
      return data == null ? null : UserProfile.fromMap(data);
    } catch (e) {
      debugPrint('[ProfileService] fetch failed: $e');
      rethrow;
    }
  }

  Future<void> delete(String uid) async {
    try {
      await _doc(uid).delete();
      debugPrint('[ProfileService] deleted profile for $uid');
    } catch (e) {
      debugPrint('[ProfileService] delete failed: $e');
      rethrow;
    }
  }
}
