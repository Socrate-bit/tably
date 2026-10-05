import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../model/recipe.dart';
import '../model/recipe_interaction.dart';
import '../service/recipe_service.dart';

part 'recipe_state.dart';

/// Owns the user's per-recipe state: favourite, cooked, rating, notes and
/// view history.
class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit({required RecipeService service, required AnalyticsService analytics})
      : _service = service,
        _analytics = analytics,
        super(const RecipeState());

  final RecipeService _service;
  final AnalyticsService _analytics;
  StreamSubscription<Map<String, RecipeInteraction>>? _stateSubscription;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _stateSubscription?.cancel();
    _stateSubscription = _service.watchInteractions(uid).listen(
      (interactions) => emit(state.copyWith(interactions: interactions, clearError: true)),
      onError: (Object e, StackTrace s) {
        AnalyticsService.reportError('RecipeCubit', 'interactions stream', e, stack: s);
        emit(state.copyWith(error: e));
      },
    );
  }

  /// Records that the user opened a recipe, feeding the "recently viewed" rail.
  Future<void> markViewed(String recipeId) {
    unawaited(_analytics.capture(AnalyticsEvents.recipeOpened, properties: {'recipe_id': recipeId}));
    return _save(state.interactionFor(recipeId).copyWith(viewedAt: DateTime.now()));
  }

  /// Favouriting saves a copy of [recipe], so it stays in the favourites even
  /// after a preferences change rebuilds the catalogue without it.
  Future<void> toggleFavourite(Recipe recipe) {
    final current = state.interactionFor(recipe.id);
    final favourite = !current.favourite;
    unawaited(_analytics.capture(
      AnalyticsEvents.recipeFavouriteToggled,
      properties: {'recipe_id': recipe.id, 'favourite': favourite},
    ));
    return _save(favourite
        ? current.copyWith(favourite: true, recipe: recipe)
        : current.copyWith(favourite: false, clearRecipe: true));
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
    } catch (e, s) {
      AnalyticsService.reportError('RecipeCubit', 'save', e, stack: s);
      emit(state.copyWith(interactions: previous, error: e));
    }
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    return super.close();
  }
}
