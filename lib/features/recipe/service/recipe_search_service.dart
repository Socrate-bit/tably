import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/util/functions_region.dart';
import '../../preferences/model/user_profile.dart';

/// Finds candidate recipes through the `searchRecipes` Cloud Function, which
/// holds the Spoonacular key. Each call spends one request of the daily quota.
class RecipeSearchService {
  RecipeSearchService({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Returns the trimmed Spoonacular recipes matching the profile's hard
  /// constraints. Throws [FirebaseFunctionsException] so the caller can tell
  /// a spent quota from an outage.
  Future<List<Map<String, dynamic>>> search(UserProfile profile) async {
    final callable = _fn.httpsCallable(
      'searchRecipes',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
    );
    final result = await callable.call<Object?>({
      'diets': [for (final d in profile.diets) d.id],
      'allergies': [for (final a in profile.allergies) a.id],
      'proteins': [for (final p in profile.proteins) p.id],
      'cookTime': profile.cookTime,
    });
    // Platform channels hand back loosely typed nested maps; a JSON round trip
    // gives plain Map<String, dynamic> all the way down.
    final data = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
    final recipes = (data['recipes'] as List? ?? const []).cast<Map<String, dynamic>>();
    debugPrint('[RecipeSearchService] found ${recipes.length} candidates');
    return recipes;
  }
}
