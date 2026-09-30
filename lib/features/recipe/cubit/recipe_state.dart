part of 'recipe_cubit.dart';

class RecipeState extends Equatable {
  const RecipeState({this.interactions = const {}, this.error});

  /// The user's favourite, cooked, rating, note and view history per recipe.
  final Map<String, RecipeInteraction> interactions;
  final Object? error;

  RecipeInteraction interactionFor(String recipeId) =>
      interactions[recipeId] ?? RecipeInteraction(recipeId: recipeId);

  bool isFavourite(String recipeId) => interactionFor(recipeId).favourite;

  /// The saved copy of every favourite, including those no longer in the
  /// catalogue. The planner can place these when the user picks one, but
  /// never picks them itself.
  List<Recipe> get savedFavourites => [
        for (final i in interactions.values)
          if (i.favourite && i.recipe != null) i.recipe!,
      ];

  /// The user's favourites, preferring the [catalogue]'s copy when it has
  /// one (it may be newer, e.g. after a language change).
  List<Recipe> favouritesIn(List<Recipe> catalogue) {
    final current = {for (final r in catalogue) r.id: r};
    final saved = {for (final r in savedFavourites) r.id: current[r.id] ?? r};
    // Favourites saved before copies existed can only come from the catalogue.
    for (final r in catalogue) {
      if (isFavourite(r.id)) saved.putIfAbsent(r.id, () => r);
    }
    return saved.values.toList()..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  /// A favourite's saved copy, for opening it once it has left the catalogue.
  Recipe? savedRecipe(String recipeId) {
    final interaction = interactions[recipeId];
    return interaction != null && interaction.favourite ? interaction.recipe : null;
  }

  /// Recipes of [catalogue] the user opened, most recent first.
  List<Recipe> recentlyViewedIn(List<Recipe> catalogue) {
    final viewed = interactions.values.where((i) => i.viewedAt != null).toList()
      ..sort((a, b) => b.viewedAt!.compareTo(a.viewedAt!));
    final byId = {for (final r in catalogue) r.id: r};
    return viewed.map((i) => byId[i.recipeId]).whereType<Recipe>().take(10).toList();
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
