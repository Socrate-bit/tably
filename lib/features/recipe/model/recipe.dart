import 'package:equatable/equatable.dart';

/// One ingredient line on a recipe.
class Ingredient extends Equatable {
  const Ingredient({required this.icon, required this.name, required this.quantity});

  final String icon;
  final String name;
  final String quantity;

  Map<String, dynamic> toMap() => {'icon': icon, 'name': name, 'quantity': quantity};

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
        icon: map['icon'] as String? ?? '🍽',
        name: map['name'] as String? ?? '',
        quantity: map['quantity'] as String? ?? '',
      );

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

  Map<String, dynamic> toMap() =>
      {'kcal': kcal, 'protein': protein, 'carbs': carbs, 'fat': fat};

  factory Macros.fromMap(Map<String, dynamic> map) => Macros(
        kcal: (map['kcal'] as num?)?.toInt() ?? 0,
        protein: (map['protein'] as num?)?.toInt() ?? 0,
        carbs: (map['carbs'] as num?)?.toInt() ?? 0,
        fat: (map['fat'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [kcal, protein, carbs, fat];
}

/// A recipe in the catalogue, stored at `recipes/{id}`.
class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.title,
    required this.photoKey,
    required this.macros,
    required this.cookTime,
    required this.servings,
    required this.price,
    required this.cravingId,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;

  /// Key into the bundled photo set (see [RecipePhotos]).
  final String photoKey;
  final Macros macros;
  final String cookTime;
  final int servings;

  /// Cost per serving in the user's currency.
  final double price;

  /// The craving this recipe satisfies — drives the badge on the menu card.
  final String cravingId;
  final List<Ingredient> ingredients;
  final List<String> steps;

  Map<String, dynamic> toMap() => {
        'title': title,
        'photoKey': photoKey,
        'macros': macros.toMap(),
        'cookTime': cookTime,
        'servings': servings,
        'price': price,
        'cravingId': cravingId,
        'ingredients': ingredients.map((i) => i.toMap()).toList(),
        'steps': steps,
      };

  factory Recipe.fromMap(String id, Map<String, dynamic> map) => Recipe(
        id: id,
        title: map['title'] as String? ?? '',
        photoKey: map['photoKey'] as String? ?? '',
        macros: Macros.fromMap(Map<String, dynamic>.from(map['macros'] as Map? ?? {})),
        cookTime: map['cookTime'] as String? ?? '',
        servings: (map['servings'] as num?)?.toInt() ?? 1,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        cravingId: map['cravingId'] as String? ?? '',
        ingredients: (map['ingredients'] as List? ?? [])
            .whereType<Map>()
            .map((m) => Ingredient.fromMap(Map<String, dynamic>.from(m)))
            .toList(),
        steps: (map['steps'] as List? ?? []).whereType<String>().toList(),
      );

  @override
  List<Object?> get props => [id, title, photoKey, macros, cookTime, servings, price, cravingId, ingredients, steps];
}

/// A cuisine tile on the explore screen.
class Cuisine extends Equatable {
  const Cuisine({required this.id, required this.name, required this.description, required this.photoKey});

  final String id;
  final String name;
  final String description;
  final String photoKey;

  Map<String, dynamic> toMap() =>
      {'name': name, 'description': description, 'photoKey': photoKey};

  factory Cuisine.fromMap(String id, Map<String, dynamic> map) => Cuisine(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        photoKey: map['photoKey'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, name, description, photoKey];
}

/// Maps a recipe's [Recipe.photoKey] to the bundled asset backing it.
abstract final class RecipePhotos {
  static const _base = 'assets/photos/';
  static const _keys = {
    'cajun', 'carbonara', 'chilli', 'curry', 'fettucine', 'friedrice',
    'handi', 'kebab', 'lasagne', 'noodle', 'pasta', 'sesame', 'stew',
  };

  /// Returns the asset path, or null when the key has no bundled photo so the
  /// caller can fall back to a neutral placeholder.
  static String? assetFor(String key) => _keys.contains(key) ? '$_base$key.jpg' : null;
}
