part of 'recipe_cubit.dart';

class RecipeState extends Equatable {
  const RecipeState({this.interactions = const {}, this.error});

  /// The user's favourite, cooked, rating, note and view history per recipe.
  final Map<String, RecipeInteraction> interactions;
  final Object? error;

  RecipeInteraction interactionFor(String recipeId) =>
      interactions[recipeId] ?? RecipeInteraction(recipeId: recipeId);

  bool isFavourite(String recipeId) => interactionFor(recipeId).favourite;

  /// Favourites in catalogue order.
  List<Recipe> get favourites =>
      RecipeCatalogue.recipes.where((r) => isFavourite(r.id)).toList();

  /// Most recently opened first, falling back to the design's picks before the
  /// user has opened anything.
  List<Recipe> get recentlyViewed {
    final viewed = interactions.values.where((i) => i.viewedAt != null).toList()
      ..sort((a, b) => b.viewedAt!.compareTo(a.viewedAt!));
    final ids = viewed.isEmpty ? RecipeCatalogue.recentIds : viewed.map((i) => i.recipeId);
    return ids.map(RecipeCatalogue.byId).whereType<Recipe>().take(10).toList();
  }

  RecipeState copyWith({
    Map<String, RecipeInteraction>? interactions,
    Object? error,
    bool clearError = false,
  }) =>
      RecipeState(
        interactions: interactions ?? this.interactions,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [interactions, error];
}
