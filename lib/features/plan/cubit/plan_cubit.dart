import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../preferences/model/user_profile.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_catalogue.dart';
import '../../shopping/service/shopping_catalogue.dart';
import '../../shopping/service/shopping_service.dart';
import '../model/planned_meal.dart';
import '../service/plan_generator.dart';
import '../service/plan_service.dart';

part 'plan_state.dart';

/// Owns the weekly plan: streams it from Firestore and regenerates it on demand.
class PlanCubit extends Cubit<PlanState> {
  PlanCubit({
    required PlanService planService,
    required ShoppingService shoppingService,
    required AnalyticsService analytics,
  })  : _plans = planService,
        _shopping = shoppingService,
        _analytics = analytics,
        super(const PlanState());

  final PlanService _plans;
  final ShoppingService _shopping;
  final AnalyticsService _analytics;
  StreamSubscription<List<PlannedMeal>>? _subscription;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    emit(state.copyWith(status: PlanStatus.loading, clearError: true));
    _subscription = _plans.watch(uid).listen(
      (meals) => emit(state.copyWith(status: PlanStatus.ready, meals: meals, clearError: true)),
      onError: (Object e) {
        debugPrint('[PlanCubit] stream error: $e');
        emit(state.copyWith(status: PlanStatus.failed, error: e));
      },
    );
  }

  /// Builds a fresh week plus its shopping list and writes both.
  Future<void> generate({
    required UserProfile profile,
    List<Recipe>? catalogue,
    bool isRegeneration = false,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    emit(state.copyWith(generating: true, clearError: true));
    try {
      final meals = PlanGenerator.generate(
        profile: profile,
        catalogue: catalogue ?? RecipeCatalogue.recipes,
      );
      // Show the new week straight away, then persist it.
      emit(state.copyWith(meals: meals, status: PlanStatus.ready));
      await _plans.replaceWeek(uid, meals);
      await _shopping.replaceList(uid, ShoppingCatalogue.buildList());
      emit(state.copyWith(generating: false));
      unawaited(_analytics.capture(
        isRegeneration ? AnalyticsEvents.planRegenerated : AnalyticsEvents.planGenerated,
        properties: {'meals': meals.length, 'household': profile.household},
      ));
      debugPrint('[PlanCubit] generated ${meals.length} meals');
    } catch (e) {
      debugPrint('[PlanCubit] generate failed: $e');
      emit(state.copyWith(generating: false, error: e));
    }
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
