part of 'catalogue_cubit.dart';

enum CatalogueStatus { loading, ready, building, failed }

/// Where a build is, driving the onboarding checklist.
enum CatalogueStep { searching, adapting, saving }

class CatalogueState extends Equatable {
  const CatalogueState({
    this.status = CatalogueStatus.loading,
    this.recipes = const [],
    this.key,
    this.keptKey,
    this.outdated = false,
    this.step = CatalogueStep.searching,
    this.error,
  });

  final CatalogueStatus status;

  /// The user's recipes, ordered by id.
  final List<Recipe> recipes;

  /// The preferences key [recipes] were built for (see [CatalogueCubit.keyFor]).
  final String? key;

  /// The newer preferences key the user chose to keep [recipes] for, so they
  /// are not asked again.
  final String? keptKey;

  /// The preferences changed in a way the recipes depend on, and the user
  /// has not yet chosen between regenerating and keeping the week.
  final bool outdated;
  final CatalogueStep step;
  final Object? error;

  bool get isBuilding => status == CatalogueStatus.building;

  Recipe? byId(String id) => recipes.where((r) => r.id == id).firstOrNull;

  CatalogueState copyWith({
    CatalogueStatus? status,
    List<Recipe>? recipes,
    String? key,
    String? keptKey,
    bool clearKeptKey = false,
    bool? outdated,
    CatalogueStep? step,
    Object? error,
    bool clearError = false,
  }) =>
      CatalogueState(
        status: status ?? this.status,
        recipes: recipes ?? this.recipes,
        key: key ?? this.key,
        keptKey: clearKeptKey ? null : (keptKey ?? this.keptKey),
        outdated: outdated ?? this.outdated,
        step: step ?? this.step,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, recipes, key, keptKey, outdated, step, error];
}
