import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/recipe.dart';
import '../model/recipe_interaction.dart';
import 'recipe_catalogue.dart';

/// Reads the shared recipe catalogue from `recipes/` and the user's per-recipe
/// state from `users/{uid}/recipeState/`.
class RecipeService {
  RecipeService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _recipes => _db.collection('recipes');

  CollectionReference<Map<String, dynamic>> _state(String uid) =>
      _db.collection('users').doc(uid).collection('recipeState');

  /// Live catalogue. Falls back to the bundled seed when Firestore is empty or
  /// unreachable, so the app is never blank.
  Stream<List<Recipe>> watchRecipes() => _recipes.snapshots().map((snap) {
        if (snap.docs.isEmpty) return RecipeCatalogue.recipes;
        return snap.docs.map((d) => Recipe.fromMap(d.id, d.data())).toList();
      }).handleError((Object e) {
        debugPrint('[RecipeService] watchRecipes failed: $e');
      });

  Stream<Map<String, RecipeInteraction>> watchInteractions(String uid) =>
      _state(uid).snapshots().map((snap) => {
            for (final doc in snap.docs)
              doc.id: RecipeInteraction.fromMap(doc.id, doc.data()),
          }).handleError((Object e) {
            debugPrint('[RecipeService] watchInteractions failed: $e');
          });

  Future<void> saveInteraction(String uid, RecipeInteraction interaction) async {
    try {
      await _state(uid).doc(interaction.recipeId).set(interaction.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[RecipeService] saveInteraction failed: $e');
      rethrow;
    }
  }

  /// Clears every saved recipe state (used by the account reset actions).
  Future<void> clearInteractions(String uid, {bool favouritesOnly = false}) async {
    try {
      final snap = await _state(uid).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        if (favouritesOnly) {
          batch.update(doc.reference, {'favourite': false});
        } else {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
      debugPrint('[RecipeService] cleared interactions (favouritesOnly=$favouritesOnly)');
    } catch (e) {
      debugPrint('[RecipeService] clearInteractions failed: $e');
      rethrow;
    }
  }

  /// Publishes the bundled catalogue once, so every client reads the same data.
  Future<void> seedCatalogueIfEmpty() async {
    try {
      final existing = await _recipes.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final batch = _db.batch();
      for (final recipe in RecipeCatalogue.recipes) {
        batch.set(_recipes.doc(recipe.id), recipe.toMap());
      }
      for (final cuisine in RecipeCatalogue.cuisines) {
        batch.set(_db.collection('cuisines').doc(cuisine.id), cuisine.toMap());
      }
      await batch.commit();
      debugPrint('[RecipeService] seeded ${RecipeCatalogue.recipes.length} recipes');
    } catch (e) {
      // Seeding is best-effort — the bundled fallback keeps the app usable.
      debugPrint('[RecipeService] seedCatalogueIfEmpty failed: $e');
    }
  }
}
