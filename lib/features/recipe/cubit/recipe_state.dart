part of 'recipe_cubit.dart';

enum RecipeStatus { loading, ready, failed }

class RecipeState extends Equatable {
  const RecipeState({
    this.status = RecipeStatus.loading,
    this.recipes = const [],
    this.interactions = const {},
    this.query = '',
    this.cravingsExpanded = true,
    this.error,
  });

  final RecipeStatus status;
  final List<Recipe> recipes;
  final Map<String, RecipeInteraction> interactions;

  /// Current search text on the explore screen.
  final String query;

  /// Whether the cravings grid is expanded ("Voir moins" / "Voir plus").
  final bool cravingsExpanded;
  final Object? error;

  RecipeInteraction interactionFor(String recipeId) =>
      interactions[recipeId] ?? RecipeInteraction(recipeId: recipeId);

  Recipe? byId(String id) => recipes.where((r) => r.id == id).firstOrNull;

  /// Recipes matching the search box; empty query returns everything.
  List<Recipe> get searchResults {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return recipes.where((r) => r.title.toLowerCase().contains(q)).toList();
  }

  /// The "recently viewed" rail: most recently opened first, falling back to
  /// the curated set before the user has opened anything.
  List<Recipe> get recentlyViewed {
    final viewed = interactions.values.where((i) => i.viewedAt != null).toList()
      ..sort((a, b) => b.viewedAt!.compareTo(a.viewedAt!));
    final fromHistory = viewed.map((i) => byId(i.recipeId)).whereType<Recipe>().toList();
    if (fromHistory.isNotEmpty) return fromHistory.take(10).toList();
    return RecipeCatalogue.recentIds.map(byId).whereType<Recipe>().toList();
  }

  List<Recipe> get favourites =>
      recipes.where((r) => interactionFor(r.id).favourite).toList();

  RecipeState copyWith({
    RecipeStatus? status,
    List<Recipe>? recipes,
    Map<String, RecipeInteraction>? interactions,
    String? query,
    bool? cravingsExpanded,
    Object? error,
    bool clearError = false,
  }) =>
      RecipeState(
        status: status ?? this.status,
        recipes: recipes ?? this.recipes,
        interactions: interactions ?? this.interactions,
        query: query ?? this.query,
        cravingsExpanded: cravingsExpanded ?? this.cravingsExpanded,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, recipes, interactions, query, cravingsExpanded, error];
}
