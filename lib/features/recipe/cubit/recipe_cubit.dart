import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../model/recipe.dart';
import '../model/recipe_interaction.dart';
import '../service/recipe_catalogue.dart';
import '../service/recipe_service.dart';

part 'recipe_state.dart';

/// Owns the recipe catalogue and the user's per-recipe state (favourite,
/// cooked, rating, notes, view history).
class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit({required RecipeService service, required AnalyticsService analytics})
      : _service = service,
        _analytics = analytics,
        super(const RecipeState(recipes: RecipeCatalogue.recipes)) {
    _catalogueSubscription = _service.watchRecipes().listen(
      (recipes) => emit(state.copyWith(status: RecipeStatus.ready, recipes: recipes)),
      onError: (Object e) {
        debugPrint('[RecipeCubit] catalogue error: $e');
        emit(state.copyWith(status: RecipeStatus.failed, error: e));
      },
    );
  }

  final RecipeService _service;
  final AnalyticsService _analytics;
  late final StreamSubscription<List<Recipe>> _catalogueSubscription;
  StreamSubscription<Map<String, RecipeInteraction>>? _stateSubscription;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _stateSubscription?.cancel();
    _stateSubscription = _service.watchInteractions(uid).listen(
      (interactions) => emit(state.copyWith(interactions: interactions, clearError: true)),
      onError: (Object e) {
        debugPrint('[RecipeCubit] interactions error: $e');
        emit(state.copyWith(error: e));
      },
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  void toggleCravingsExpanded() =>
      emit(state.copyWith(cravingsExpanded: !state.cravingsExpanded));

  /// Records that the user opened a recipe, feeding the "recently viewed" rail.
  Future<void> markViewed(String recipeId) {
    unawaited(_analytics.capture(AnalyticsEvents.recipeOpened, properties: {'recipe_id': recipeId}));
    return _save(state.interactionFor(recipeId).copyWith(viewedAt: DateTime.now()));
  }

  Future<void> toggleFavourite(String recipeId) {
    final next = state.interactionFor(recipeId);
    unawaited(_analytics.capture(
      AnalyticsEvents.recipeFavouriteToggled,
      properties: {'recipe_id': recipeId, 'favourite': !next.favourite},
    ));
    return _save(next.copyWith(favourite: !next.favourite));
  }

  Future<void> toggleCooked(String recipeId) {
    final next = state.interactionFor(recipeId);
    unawaited(_analytics.capture(
      AnalyticsEvents.recipeCookedToggled,
      properties: {'recipe_id': recipeId, 'cooked': !next.cooked},
    ));
    return _save(next.copyWith(cooked: !next.cooked));
  }

  Future<void> setRating(String recipeId, int rating) =>
      _save(state.interactionFor(recipeId).copyWith(rating: rating));

  Future<void> setNote(String recipeId, String note) =>
      _save(state.interactionFor(recipeId).copyWith(note: note));

  /// Clears favourites (or the whole history) from the account screen.
  Future<void> reset({required bool favouritesOnly}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.clearInteractions(uid, favouritesOnly: favouritesOnly);
      debugPrint('[RecipeCubit] reset interactions (favouritesOnly=$favouritesOnly)');
    } catch (e) {
      debugPrint('[RecipeCubit] reset failed: $e');
      emit(state.copyWith(error: e));
    }
  }

  /// Applies the change locally first so the UI never waits on the network.
  Future<void> _save(RecipeInteraction interaction) async {
    final previous = state.interactions;
    emit(state.copyWith(
      interactions: {...previous, interaction.recipeId: interaction},
      clearError: true,
    ));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.saveInteraction(uid, interaction);
    } catch (e) {
      debugPrint('[RecipeCubit] save failed: $e');
      emit(state.copyWith(interactions: previous, error: e));
    }
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _catalogueSubscription.cancel();
    _stateSubscription?.cancel();
    return super.close();
  }
}
