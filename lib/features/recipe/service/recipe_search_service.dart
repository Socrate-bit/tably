import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/util/functions_region.dart';
import '../../../core/model/preference_option.dart';
import '../../preferences/model/user_profile.dart';
import '../model/recipe.dart';

/// Finds candidate recipes through the `searchRecipes` Cloud Function, which
/// holds the Spoonacular key. Each call spends one request of the daily quota.
class RecipeSearchService {
  RecipeSearchService({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Returns up to [number] trimmed Spoonacular recipes matching the
  /// profile's hard constraints, narrowed by the optional search filters:
  /// English [query] text, [cuisines], one [craving] and one [protein].
  /// Throws [FirebaseFunctionsException] so the caller can tell a spent quota
  /// from an outage.
  Future<List<Map<String, dynamic>>> search(
    UserProfile profile, {
    required int number,
    String? query,
    Set<Cuisine> cuisines = const {},
    Craving? craving,
    RecipeProtein? protein,
  }) async {
    final callable = _fn.httpsCallable(
      'searchRecipes',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
    );
    final result = await callable.call<Object?>({
      'diets': [for (final d in profile.diets) d.id],
      'allergies': [for (final a in profile.allergies) a.id],
      'proteins': [for (final p in profile.proteins) p.id],
      'cookTime': profile.cookTime,
      'number': number,
      'query': query,
      'cuisines': [for (final c in cuisines) c.id],
      'craving': craving?.id,
      'protein': protein?.id,
    });
    // Platform channels hand back loosely typed nested maps; a JSON round trip
    // gives plain Map<String, dynamic> all the way down.
    final data = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
    final recipes = (data['recipes'] as List? ?? const []).cast<Map<String, dynamic>>();
    debugPrint('[RecipeSearchService] found ${recipes.length} candidates');
    return recipes;
  }
}
