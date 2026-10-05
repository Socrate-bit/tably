import 'package:equatable/equatable.dart';

import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../../core/model/preference_option.dart';

/// One ingredient line on a recipe.
class Ingredient extends Equatable {
  const Ingredient({
    required this.id,
    required this.icon,
    required this.name,
    required this.amount,
    required this.unit,
    required this.aisle,
  });

  /// Spoonacular's ingredient id. The same food shares it across recipes,
  /// which is how the shopping list merges them.
  final int id;
  final String icon;
  final String name;

  /// How much one portion needs, in [unit].
  final double amount;

  /// One of a fixed set of units, so the shopping list can sum it.
  final IngredientUnit unit;
  final Aisle aisle;

  Map<String, dynamic> toMap() => {
        'id': id,
        'icon': icon,
        'name': name,
        'amount': amount,
        'unit': unit.id,
        'aisle': aisle.id,
      };

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
        id: (map['id'] as num?)?.toInt() ?? 0,
        icon: map['icon'] as String? ?? '🍽️',
        name: map['name'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        unit: IngredientUnit.fromId(map['unit'] as String?),
        aisle: Aisle.fromId(map['aisle'] as String?),
      );

  @override
  List<Object?> get props => [id, icon, name, amount, unit, aisle];
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

  Map<String, dynamic> toMap() => {'kcal': kcal, 'protein': protein, 'carbs': carbs, 'fat': fat};

  factory Macros.fromMap(Map<String, dynamic> map) {
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return Macros(kcal: read('kcal'), protein: read('protein'), carbs: read('carbs'), fat: read('fat'));
  }

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

  static RecipeProtein fromId(String? id) =>
      values.firstWhere((p) => p.id == id, orElse: () => vegetarian);
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

  /// Null for anything outside the five the filters offer.
  static Cuisine? fromId(String? id) => values.where((c) => c.id == id).firstOrNull;
}

/// A recipe in the user's catalogue, stored at `users/{uid}/recipes/{id}`.
class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.title,
    required this.photoUrl,
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

  /// Remote photo; empty shows the neutral placeholder.
  final String photoUrl;
  final Macros macros;

  /// Total time shown on cards, e.g. "25m".
  final String time;

  /// Cooking time shown in the recipe notes, e.g. "20-25m".
  final String cookTime;

  /// [time] in minutes, or null when it holds no number.
  int? get minutes => int.tryParse(time.replaceAll(RegExp(r'\D'), ''));

  /// Whether this recipe answers [wanted]: its own badge, or for the
  /// measurable cravings the thresholds the search and Gemini use. A recipe
  /// has one badge, so a quick dish with 40 g of protein is high protein too.
  bool satisfies(Craving wanted) =>
      wanted == craving ||
      switch (wanted) {
        Craving.quick => (minutes ?? 0) > 0 && minutes! <= 25,
        Craving.highProtein => macros.protein >= 30,
        Craving.lowCalorie => macros.kcal > 0 && macros.kcal <= 450,
        _ => false,
      };

  /// Reference cost per portion, scaled by the store's price factor.
  final double price;

  /// The craving this recipe satisfies — drives its badge and filters.
  final Craving craving;
  final RecipeProtein protein;
  final Cuisine? cuisine;

  /// Credited source, shown over the photo.
  final String? creator;
  final List<Ingredient> ingredients;
  final List<String> steps;

  Map<String, dynamic> toMap() => {
        'title': title,
        'photoUrl': photoUrl,
        'macros': macros.toMap(),
        'time': time,
        'cookTime': cookTime,
        'price': price,
        'craving': craving.id,
        'protein': protein.id,
        'cuisine': cuisine?.id,
        'creator': creator,
        'ingredients': [for (final i in ingredients) i.toMap()],
        'steps': steps,
      };

  factory Recipe.fromMap(String id, Map<String, dynamic> map) => Recipe(
        id: id,
        title: map['title'] as String? ?? '',
        photoUrl: map['photoUrl'] as String? ?? '',
        macros: Macros.fromMap(Map<String, dynamic>.from(map['macros'] as Map? ?? const {})),
        time: map['time'] as String? ?? '',
        cookTime: map['cookTime'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        craving: Craving.values.firstWhere((c) => c.id == map['craving'], orElse: () => Craving.quick),
        protein: RecipeProtein.fromId(map['protein'] as String?),
        cuisine: Cuisine.fromId(map['cuisine'] as String?),
        creator: map['creator'] as String?,
        ingredients: [
          for (final i in map['ingredients'] as List? ?? const [])
            if (i is Map) Ingredient.fromMap(Map<String, dynamic>.from(i)),
        ],
        steps: (map['steps'] as List? ?? const []).whereType<String>().toList(),
      );

  @override
  List<Object?> get props =>
      [id, title, photoUrl, macros, time, cookTime, price, craving, protein, cuisine, creator, ingredients, steps];
}

/// Maps a bundled photo key (cuisine tiles, onboarding art) to its asset.
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
