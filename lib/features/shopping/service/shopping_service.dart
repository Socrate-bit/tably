import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/shopping_item.dart';

/// Reads and writes the shopping list at `users/{uid}/shopping/{itemId}`.
class ShoppingService {
  ShoppingService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('shopping');

  /// Live list, in list order.
  Stream<List<ShoppingItem>> watch(String uid) => _col(uid).snapshots().map((snap) {
        final items = snap.docs.map((d) => ShoppingItem.fromMap(d.id, d.data())).toList();
        items.sort((a, b) => a.order.compareTo(b.order));
        return items;
      });

  /// Writes [items] and deletes [removedIds] in one batch.
  Future<void> replaceList(String uid, List<ShoppingItem> items, Iterable<String> removedIds) async {
    try {
      final col = _col(uid);
      final batch = _db.batch();
      for (final id in removedIds) {
        batch.delete(col.doc(id));
      }
      for (final item in items) {
        batch.set(col.doc(item.id), item.toMap());
      }
      await batch.commit();
      debugPrint('[ShoppingService] list replaced with ${items.length} items for $uid');
    } catch (e) {
      debugPrint('[ShoppingService] replaceList failed: $e');
      rethrow;
    }
  }

  Future<void> setChecked(String uid, String itemId, bool checked) async {
    try {
      await _col(uid).doc(itemId).update({'checked': checked});
    } catch (e) {
      debugPrint('[ShoppingService] setChecked failed: $e');
      rethrow;
    }
  }
}
