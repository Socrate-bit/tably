import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/recipe.dart';
import '../model/recipe_interaction.dart';

/// Reads and writes the user's recipes at `users/{uid}/recipes/`, the key of
/// the preferences they were built for at `users/{uid}/plan/catalogue`, and
/// the per-recipe state at `users/{uid}/recipeState/`.
class RecipeService {
  RecipeService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _state(String uid) =>
      _db.collection('users').doc(uid).collection('recipeState');

  CollectionReference<Map<String, dynamic>> _recipes(String uid) =>
      _db.collection('users').doc(uid).collection('recipes');

  DocumentReference<Map<String, dynamic>> _catalogue(String uid) =>
      _db.collection('users').doc(uid).collection('plan').doc('catalogue');

  /// The user's catalogue, ordered by id so the planner's shuffle is stable.
  Stream<List<Recipe>> watchCatalogue(String uid) => _recipes(uid).snapshots().map((snap) {
        final recipes = [for (final doc in snap.docs) Recipe.fromMap(doc.id, doc.data())];
        return recipes..sort((a, b) => a.id.compareTo(b.id));
      });

  /// The preferences key the stored catalogue was built for, or null if
  /// none, and the newer key the user chose to keep it for, if any.
  Stream<({String? key, String? keptKey})> watchCatalogueKeys(String uid) =>
      _catalogue(uid).snapshots().map((snap) => (
            key: snap.data()?['key'] as String?,
            keptKey: snap.data()?['keptKey'] as String?,
          ));

  /// Records that the user kept the catalogue although their preferences
  /// changed to [keptKey]. A rebuild clears it.
  Future<void> keepCatalogue(String uid, String keptKey) async {
    try {
      await _catalogue(uid).update({'keptKey': keptKey});
      debugPrint('[RecipeService] catalogue kept for $keptKey');
    } catch (e) {
      debugPrint('[RecipeService] keepCatalogue failed: $e');
      rethrow;
    }
  }

  /// Adds one recipe to the catalogue.
  Future<void> saveRecipe(String uid, Recipe recipe) async {
    try {
      await _recipes(uid).doc(recipe.id).set(recipe.toMap());
      debugPrint('[RecipeService] added recipe ${recipe.id} to the catalogue');
    } catch (e) {
      debugPrint('[RecipeService] saveRecipe failed: $e');
      rethrow;
    }
  }

  /// Swaps the whole catalogue for [recipes] in one batch, recording [key].
  Future<void> replaceCatalogue(String uid, List<Recipe> recipes, String key) async {
    try {
      final col = _recipes(uid);
      final keep = {for (final r in recipes) r.id};
      final existing = await col.get();
      final batch = _db.batch();
      for (final doc in existing.docs) {
        if (!keep.contains(doc.id)) batch.delete(doc.reference);
      }
      for (final recipe in recipes) {
        batch.set(col.doc(recipe.id), recipe.toMap());
      }
      batch.set(_catalogue(uid), {'key': key, 'builtAt': FieldValue.serverTimestamp()});
      await batch.commit();
      debugPrint('[RecipeService] catalogue replaced with ${recipes.length} recipes for $uid');
    } catch (e) {
      debugPrint('[RecipeService] replaceCatalogue failed: $e');
      rethrow;
    }
  }

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
}
