import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Reads the user's daily recipe-search count at `searchQuota/{uid}`. Only
/// the `searchRecipes` function writes it, one search at a time.
class SearchQuotaService {
  SearchQuotaService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// The UTC day ("YYYY-MM-DD") of the last search and how many ran that
  /// day; no day when the user never searched.
  Stream<({String? day, int count})> watch(String uid) =>
      _db.collection('searchQuota').doc(uid).snapshots().map((snap) {
        final data = snap.data();
        debugPrint('[SearchQuotaService] ${data?['count'] ?? 0} searches on ${data?['day']}');
        return (day: data?['day'] as String?, count: (data?['count'] as num?)?.toInt() ?? 0);
      });
}
