import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/util/functions_region.dart';
import '../../../core/model/preference_option.dart';
import '../../preferences/model/user_profile.dart';
import '../model/recipe.dart';

/// Reaches Spoonacular through the `searchRecipes` and `spoonacular` Cloud
/// Functions, which hold the key. Each call spends one of the user's daily
/// searches (see SearchQuotaCubit) and API quota.
class RecipeSearchService {
  RecipeSearchService({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Returns up to [number] trimmed Spoonacular recipes matching the
  /// profile's hard constraints, narrowed by the optional search filters:
  /// English [query] text, [cuisines] and one [craving]. An English [wish]
  /// from the custom instructions is searched first, then topped up with
  /// plain results, still one search of the quota.
  /// Throws [FirebaseFunctionsException] so the caller can tell a spent quota
  /// from an outage.
  Future<List<Map<String, dynamic>>> search(
    UserProfile profile, {
    required int number,
    String? query,
    Set<Cuisine> cuisines = const {},
    Craving? craving,
    String? wish,
  }) async {
    final data = await invoke('searchRecipes', {
      ..._constraints(profile),
      'number': number,
      'query': query,
      'cuisines': [for (final c in cuisines) c.id],
      'craving': craving?.id,
      'wish': wish,
    });
    final recipes = _recipes(data);
    debugPrint('[RecipeSearchService] found ${recipes.length} candidates');
    return recipes;
  }

  // The AI chef's calls go through the `spoonacular` function, and count
  // against the same daily searches.

  /// A handful of recipes matching the profile's hard constraints, narrowed
  /// like [search], and using as many of [includeIngredients] as possible.
  Future<List<Map<String, dynamic>>> agentSearch(
    UserProfile profile, {
    String? query,
    List<String> includeIngredients = const [],
    Set<Cuisine> cuisines = const {},
    Craving? craving,
    RecipeProtein? protein,
  }) async =>
      _recipes(await invoke('spoonacular', {
        'action': 'search',
        ..._constraints(profile),
        'query': query,
        'includeIngredients': includeIngredients,
        'cuisines': [for (final c in cuisines) c.id],
        'craving': craving?.id,
        'protein': protein?.id,
      }));

  /// Recipes like the Spoonacular recipe [id].
  Future<List<Map<String, dynamic>>> similar(int id) async =>
      _recipes(await invoke('spoonacular', {'action': 'similar', 'id': id}));

  /// The recipe on the web page at [url]; empty when the page has none.
  Future<List<Map<String, dynamic>>> extract(String url) async =>
      _recipes(await invoke('spoonacular', {'action': 'extract', 'url': url}));

  /// What can replace the English [ingredient], with Spoonacular's note.
  Future<Map<String, dynamic>> substitutes(String ingredient) =>
      invoke('spoonacular', {'action': 'substitutes', 'ingredient': ingredient});

  /// Wines that go with the English [food], at most [maxPrice] dollars.
  Future<Map<String, dynamic>> winePairing(String food, {double? maxPrice}) =>
      invoke('spoonacular', {'action': 'winePairing', 'food': food, 'maxPrice': maxPrice});

  /// The profile's hard constraints, which every search applies.
  static Map<String, Object?> _constraints(UserProfile profile) => {
        'diets': [for (final d in profile.diets) d.id],
        'allergies': [for (final a in profile.allergies) a.id],
        'proteins': [for (final p in profile.proteins) p.id],
        'maxReadyTime': profile.hasCookLimit ? profile.cookMinutes : null,
      };

  /// Calls the function [name]. Throws [FirebaseFunctionsException] so the
  /// caller can tell a spent quota from an outage. The AI chef eval replaces
  /// it to reach the functions emulator.
  @protected
  Future<Map<String, dynamic>> invoke(String name, Map<String, Object?> data) async {
    final callable = _fn.httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 70)));
    final result = await callable.call<Object?>(data);
    // Platform channels hand back loosely typed nested maps; a JSON round trip
    // gives plain Map<String, dynamic> all the way down.
    return jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> _recipes(Map<String, dynamic> data) =>
      (data['recipes'] as List? ?? const []).cast<Map<String, dynamic>>();
}
