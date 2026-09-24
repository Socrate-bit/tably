import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/recipe_interaction.dart';

/// Reads and writes the user's per-recipe state at `users/{uid}/recipeState/`.
/// The catalogue itself is bundled with the app (see [RecipeCatalogue]).
class RecipeService {
  RecipeService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _state(String uid) =>
      _db.collection('users').doc(uid).collection('recipeState');

  Stream<Map<String, RecipeInteraction>> watchInteractions(String uid) =>
      _state(uid).snapshots().map((snap) => {
            for (final doc in snap.docs) doc.id: RecipeInteraction.fromMap(doc.id, doc.data()),
          });

  Future<void> saveInteraction(String uid, RecipeInteraction interaction) async {
    try {
      await _state(uid).doc(interaction.recipeId).set(interaction.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[RecipeService] saveInteraction failed: $e');
      rethrow;
    }
  }

  /// Clears favourites, or every saved recipe state, for the account reset actions.
  Future<void> clearInteractions(String uid, {bool favouritesOnly = false}) async {
    try {
      final snap = await _state(uid).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        favouritesOnly ? batch.update(doc.reference, {'favourite': false}) : batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[RecipeService] cleared interactions (favouritesOnly=$favouritesOnly)');
    } catch (e) {
      debugPrint('[RecipeService] clearInteractions failed: $e');
      rethrow;
    }
  }
}
