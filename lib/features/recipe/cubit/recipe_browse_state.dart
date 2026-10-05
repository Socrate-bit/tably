part of 'recipe_browse_cubit.dart';

class RecipeBrowseState extends Equatable {
  const RecipeBrowseState({
    this.query = '',
    this.cravings = const {},
    this.cuisines = const {},
    this.proteins = const {},
    this.maxPrice = RecipeBrowseCubit.priceCeiling,
    this.constraints = const DietaryConstraints(),
  });

  /// Text in the search box.
  final String query;
  final Set<Craving> cravings;
  final Set<Cuisine> cuisines;
  final Set<RecipeProtein> proteins;

  /// Highest price per portion to show; the ceiling means "no limit".
  final double maxPrice;

  /// Diets, allergies and appliances the search respects.
  final DietaryConstraints constraints;

  bool get isSearching => query.trim().isNotEmpty;

  bool get hasPriceLimit => maxPrice < RecipeBrowseCubit.priceCeiling;

  /// Whether a portion costing [price] at the reference fits the price limit
  /// once scaled to [store].
  bool fitsPrice(double price, Store store) => !hasPriceLimit || price * store.priceFactor <= maxPrice;

  /// The badge count on the filter button: one per chip, plus one for price,
  /// plus one per diet, allergy or appliance narrower than the widest search,
  /// plus one for a time limit.
  int get filterCount =>
      cravings.length +
      cuisines.length +
      proteins.length +
      (hasPriceLimit ? 1 : 0) +
      constraints.differencesFrom(widest);

  bool get hasFilters => filterCount > 0;

  /// No diet, no allergy and every appliance.
  static final widest = DietaryConstraints(appliances: Appliance.values.toSet());

  /// This search with every filter at its most permissive.
  RecipeBrowseState get cleared => RecipeBrowseState(
        query: query,
        constraints: widest,
      );

  /// Whether "Réinitialiser" would change anything.
  bool get canReset => this != cleared;

  /// The craving and protein the API narrows by: only a single pick, as it
  /// combines filters with AND. Several are left to [apply].
  Craving? get searchCraving => cravings.length == 1 ? cravings.single : null;
  RecipeProtein? get searchProtein => proteins.length == 1 ? proteins.single : null;

  /// Whether there is anything to search the API for.
  bool get canSearch => isSearching || hasFilters;

  /// Recipes that pass the filters and match every word of the search.
  /// [searchText] defaults to [query]; the replace sheet has its own box.
  /// [cravingLabel] lets the search match badge names in the user's language.
  /// [searched] marks API results for this state: the API already matched
  /// the text, the cuisines and a single craving or protein, so they are not
  /// checked again against Gemini's labels, which often disagree.
  List<Recipe> apply(
    List<Recipe> recipes, {
    required Store store,
    required String Function(Craving) cravingLabel,
    String? searchText,
    bool searched = false,
  }) {
    final text = searched ? '' : searchText ?? query;
    final words = text.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final checkCravings = cravings.isNotEmpty && !(searched && searchCraving != null);
    final checkProteins = proteins.isNotEmpty && !(searched && searchProtein != null);
    return recipes.where((r) {
      if (checkCravings && !cravings.any(r.satisfies)) return false;
      if (!searched && cuisines.isNotEmpty && !cuisines.contains(r.cuisine)) return false;
      if (checkProteins && !proteins.contains(r.protein)) return false;
      if (!fitsPrice(r.price, store)) return false;
      if (constraints.hasCookLimit && (r.minutes ?? 0) > constraints.cookMinutes) return false;
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
    DietaryConstraints? constraints,
  }) =>
      RecipeBrowseState(
        query: query ?? this.query,
        cravings: cravings ?? this.cravings,
        cuisines: cuisines ?? this.cuisines,
        proteins: proteins ?? this.proteins,
        maxPrice: maxPrice ?? this.maxPrice,
        constraints: constraints ?? this.constraints,
      );

  @override
  List<Object?> get props => [query, cravings, cuisines, proteins, maxPrice, constraints];
}
