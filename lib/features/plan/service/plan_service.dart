import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/model/weekday.dart';
import '../model/planned_meal.dart';

/// Reads and writes the weekly plan at `users/{uid}/plan/{day}`.
class PlanService {
  PlanService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('plan');

  /// Live plan, ordered by day of week.
  Stream<List<PlannedMeal>> watch(String uid) => _col(uid).snapshots().map((snap) {
        final meals = snap.docs.map((d) => PlannedMeal.fromMap(d.data())).toList();
        meals.sort((a, b) => a.day.index.compareTo(b.day.index));
        return meals;
      }).handleError((Object e) {
        debugPrint('[PlanService] watch failed: $e');
      });

  /// Replaces the whole week atomically so the UI never shows a half-written plan.
  Future<void> replaceWeek(String uid, List<PlannedMeal> meals) async {
    try {
      final col = _col(uid);
      final existing = await col.get();
      final batch = _db.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (final meal in meals) {
        batch.set(col.doc(meal.day.id), meal.toMap());
      }
      await batch.commit();
      debugPrint('[PlanService] wrote ${meals.length} meals for $uid');
    } catch (e) {
      debugPrint('[PlanService] replaceWeek failed: $e');
      rethrow;
    }
  }

  /// Swaps a single day's dinner.
  Future<void> setMeal(String uid, PlannedMeal meal) async {
    try {
      await _col(uid).doc(meal.day.id).set(meal.toMap());
      debugPrint('[PlanService] set meal for ${meal.day.id}');
    } catch (e) {
      debugPrint('[PlanService] setMeal failed: $e');
      rethrow;
    }
  }

  Future<void> removeDay(String uid, Weekday day) async {
    try {
      await _col(uid).doc(day.id).delete();
    } catch (e) {
      debugPrint('[PlanService] removeDay failed: $e');
      rethrow;
    }
  }
}
