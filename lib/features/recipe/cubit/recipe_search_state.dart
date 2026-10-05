part of 'recipe_search_cubit.dart';

enum RecipeSearchStatus { idle, searching, ready, failed }

class RecipeSearchState extends Equatable {
  const RecipeSearchState({
    this.status = RecipeSearchStatus.idle,
    this.searchedFor,
    this.results = const [],
    this.error,
  });

  final RecipeSearchStatus status;

  /// The search text and filters [results] were fetched for.
  final RecipeBrowseState? searchedFor;
  final List<Recipe> results;
  final Object? error;

  /// The results for exactly [browse], or null when they were fetched for
  /// another search (or none ran) — the tab then shows the cached pool.
  List<Recipe>? resultsFor(RecipeBrowseState browse) =>
      status == RecipeSearchStatus.ready && searchedFor == browse ? results : null;

  bool isSearchingFor(RecipeBrowseState browse) => status == RecipeSearchStatus.searching && searchedFor == browse;

  /// Whether a list shows the search for [browse] — typed text, its results
  /// or the search running — rather than the cached pool.
  bool showsSearch(RecipeBrowseState browse) =>
      browse.isSearching || resultsFor(browse) != null || isSearchingFor(browse);

  Recipe? byId(String id) => results.where((r) => r.id == id).firstOrNull;

  @override
  List<Object?> get props => [status, searchedFor, results, error];
}
