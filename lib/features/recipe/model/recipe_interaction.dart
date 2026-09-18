import 'package:equatable/equatable.dart';

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
  });

  final String recipeId;
  final bool favourite;
  final bool cooked;

  /// 0 means unrated.
  final int rating;
  final String note;
  final DateTime? viewedAt;

  RecipeInteraction copyWith({
    bool? favourite,
    bool? cooked,
    int? rating,
    String? note,
    DateTime? viewedAt,
  }) =>
      RecipeInteraction(
        recipeId: recipeId,
        favourite: favourite ?? this.favourite,
        cooked: cooked ?? this.cooked,
        rating: rating ?? this.rating,
        note: note ?? this.note,
        viewedAt: viewedAt ?? this.viewedAt,
      );

  Map<String, dynamic> toMap() => {
        'favourite': favourite,
        'cooked': cooked,
        'rating': rating,
        'note': note,
        if (viewedAt != null) 'viewedAt': viewedAt!.toIso8601String(),
      };

  factory RecipeInteraction.fromMap(String recipeId, Map<String, dynamic> map) => RecipeInteraction(
        recipeId: recipeId,
        favourite: map['favourite'] as bool? ?? false,
        cooked: map['cooked'] as bool? ?? false,
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        note: map['note'] as String? ?? '',
        viewedAt: DateTime.tryParse(map['viewedAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [recipeId, favourite, cooked, rating, note, viewedAt];
}
