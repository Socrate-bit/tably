import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';

/// One ingredient line on a recipe.
class Ingredient extends Equatable {
  const Ingredient({required this.icon, required this.name, required this.quantity});

  final String icon;
  final String name;
  final String quantity;

  @override
  List<Object?> get props => [icon, name, quantity];
}

/// Per-serving macro breakdown shown on the recipe screen.
class Macros extends Equatable {
  const Macros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  @override
  List<Object?> get props => [kcal, protein, carbs, fat];
}

/// The main protein of a recipe, used by the filters screen.
enum RecipeProtein {
  beef('beef', '🥩'),
  pork('pork', '🥓'),
  chicken('chicken', '🍗'),
  fish('fish', '🐟'),
  vegetarian('vegetarian', '🥕'),
  tofu('tofu', '🧈');

  const RecipeProtein(this.id, this.icon);
  final String id;
  final String icon;
}

/// A cuisine the filters screen can narrow recipes to.
enum Cuisine {
  italian('italian', 'lasagne'),
  asian('asian', 'noodle'),
  mexican('mexican', 'chilli'),
  indian('indian', 'curry'),
  mediterranean('mediterranean', 'kebab');

  const Cuisine(this.id, this.photoKey);
  final String id;
  final String photoKey;
}

/// A recipe in the bundled catalogue.
class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.title,
    required this.photoKey,
    required this.macros,
    required this.time,
    required this.cookTime,
    required this.price,
    required this.craving,
    required this.protein,
    required this.ingredients,
    required this.steps,
    this.cuisine,
    this.creator,
  });

  final String id;
  final String title;

  /// Key into the bundled photo set (see [RecipePhotos]); also a search keyword.
  final String photoKey;
  final Macros macros;

  /// Total time shown on cards, e.g. "25m".
  final String time;

  /// Cooking time shown in the recipe notes, e.g. "20-25m".
  final String cookTime;

  /// Reference cost per portion, scaled by the store's price factor.
  final double price;

  /// The craving this recipe satisfies — drives its badge and filters.
  final Craving craving;
  final RecipeProtein protein;
  final Cuisine? cuisine;

  /// Credited author, shown over the photo when the recipe comes from a creator.
  final String? creator;
  final List<Ingredient> ingredients;
  final List<String> steps;

  @override
  List<Object?> get props =>
      [id, title, photoKey, macros, time, cookTime, price, craving, protein, cuisine, creator, ingredients, steps];
}

/// Maps a recipe's [Recipe.photoKey] to the bundled asset backing it.
abstract final class RecipePhotos {
  static const _base = 'assets/photos/';
  static const _keys = {
    'bigmac', 'cajun', 'carbonara', 'chilli', 'curry', 'fettucine', 'friedrice',
    'handi', 'kebab', 'lasagne', 'noodle', 'pasta', 'sesame', 'stew',
  };

  /// Returns the asset path, or null when the key has no bundled photo so the
  /// caller can fall back to a neutral placeholder.
  static String? assetFor(String key) => _keys.contains(key) ? '$_base$key.jpg' : null;
}
