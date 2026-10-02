part of 'recipe_browse_cubit.dart';

class RecipeBrowseState extends Equatable {
  const RecipeBrowseState({
    this.query = '',
    this.cravings = const {},
    this.cuisines = const {},
    this.proteins = const {},
    this.maxPrice = RecipeBrowseCubit.priceCeiling,
  });

  /// Text in the search box.
  final String query;
  final Set<Craving> cravings;
  final Set<Cuisine> cuisines;
  final Set<RecipeProtein> proteins;

  /// Highest price per portion to show; the ceiling means "no limit".
  final double maxPrice;

  bool get isSearching => query.trim().isNotEmpty;

  bool get hasPriceLimit => maxPrice < RecipeBrowseCubit.priceCeiling;

  /// The badge count on the filter button: one per chip, plus one for price.
  int get filterCount => cravings.length + cuisines.length + proteins.length + (hasPriceLimit ? 1 : 0);

  bool get hasFilters => filterCount > 0;

  /// Whether there is anything to search the API for.
  bool get canSearch => isSearching || hasFilters;

  /// Recipes that pass the filters and match every word of the search.
  /// [searchText] defaults to [query]; the replace sheet has its own box.
  /// [cravingLabel] lets the search match badge names in the user's language.
  List<Recipe> apply(
    List<Recipe> recipes, {
    required Store store,
    required String Function(Craving) cravingLabel,
    String? searchText,
  }) {
    final words = (searchText ?? query).trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return recipes.where((r) {
      if (cravings.isNotEmpty && !cravings.contains(r.craving)) return false;
      if (cuisines.isNotEmpty && !cuisines.contains(r.cuisine)) return false;
      if (proteins.isNotEmpty && !proteins.contains(r.protein)) return false;
      if (hasPriceLimit && r.price * store.priceFactor > maxPrice) return false;
      final haystack = '${r.title} ${cravingLabel(r.craving)}'.toLowerCase();
      return words.every(haystack.contains);
    }).toList();
  }

  RecipeBrowseState copyWith({
    String? query,
    Set<Craving>? cravings,
    Set<Cuisine>? cuisines,
    Set<RecipeProtein>? proteins,
    double? maxPrice,
  }) =>
      RecipeBrowseState(
        query: query ?? this.query,
        cravings: cravings ?? this.cravings,
        cuisines: cuisines ?? this.cuisines,
        proteins: proteins ?? this.proteins,
        maxPrice: maxPrice ?? this.maxPrice,
      );

  @override
  List<Object?> get props => [query, cravings, cuisines, proteins, maxPrice];
}
