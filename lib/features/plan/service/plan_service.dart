import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/plan_settings.dart';

/// Reads and writes the user's plan settings at `users/{uid}/plan/week`.
class PlanService {
  PlanService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('plan').doc('week');

  /// Live settings; a user who never regenerated or swapped gets the defaults.
  Stream<PlanSettings> watch(String uid) => _doc(uid).snapshots().map((snap) {
        final data = snap.data();
        return data == null ? const PlanSettings() : PlanSettings.fromMap(data);
      });

  Future<void> save(String uid, PlanSettings settings) async {
    try {
      await _doc(uid).set(settings.toMap());
      debugPrint('[PlanService] saved plan (seed ${settings.seed}, ${settings.overrides.length} swaps)');
    } catch (e) {
      debugPrint('[PlanService] save failed: $e');
      rethrow;
    }
  }
}
