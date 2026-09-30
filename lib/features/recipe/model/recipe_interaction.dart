import 'package:equatable/equatable.dart';

import 'recipe.dart';

/// The user's private state for one recipe, stored at
/// `users/{uid}/recipeState/{recipeId}`.
class RecipeInteraction extends Equatable {
  const RecipeInteraction({
    required this.recipeId,
    this.favourite = false,
    this.cooked = false,
    this.rating = 0,
    this.note = '',
    this.viewedAt,
    this.recipe,
  });

  final String recipeId;
  final bool favourite;
  final bool cooked;

  /// 0 means unrated.
  final int rating;
  final String note;
  final DateTime? viewedAt;

  /// The recipe as it was when favourited, so it outlives the catalogue being
  /// rebuilt. Null when not a favourite.
  final Recipe? recipe;

  RecipeInteraction copyWith({
    bool? favourite,
    bool? cooked,
    int? rating,
    String? note,
    DateTime? viewedAt,
    Recipe? recipe,
    bool clearRecipe = false,
  }) =>
      RecipeInteraction(
        recipeId: recipeId,
        favourite: favourite ?? this.favourite,
        cooked: cooked ?? this.cooked,
        rating: rating ?? this.rating,
        note: note ?? this.note,
        viewedAt: viewedAt ?? this.viewedAt,
        recipe: clearRecipe ? null : (recipe ?? this.recipe),
      );

  Map<String, dynamic> toMap() => {
        'favourite': favourite,
        'cooked': cooked,
        'rating': rating,
        'note': note,
        if (viewedAt != null) 'viewedAt': viewedAt!.toIso8601String(),
        // Written as null on unfavourite, so the merge clears the copy.
        'recipe': recipe?.toMap(),
      };

  factory RecipeInteraction.fromMap(String recipeId, Map<String, dynamic> map) => RecipeInteraction(
        recipeId: recipeId,
        favourite: map['favourite'] as bool? ?? false,
        cooked: map['cooked'] as bool? ?? false,
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        note: map['note'] as String? ?? '',
        viewedAt: DateTime.tryParse(map['viewedAt'] as String? ?? ''),
        recipe: map['recipe'] is Map ? Recipe.fromMap(recipeId, Map<String, dynamic>.from(map['recipe'] as Map)) : null,
      );

  @override
  List<Object?> get props => [recipeId, favourite, cooked, rating, note, viewedAt, recipe];
}
