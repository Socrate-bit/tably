import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/store.dart';
import '../../plan/cubit/plan_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../recipe/cubit/recipe_cubit.dart';
import '../../recipe/cubit/search_quota_cubit.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_ai_service.dart';
import '../../recipe/service/recipe_search_service.dart';
import '../../shopping/cubit/shopping_cubit.dart';
import 'chat_tool.dart';
import 'plan_tools.dart';
import 'preference_tools.dart';
import 'recipe_tools.dart';
import 'shopping_tools.dart';
import 'spoonacular_tools.dart';
import 'tool_payloads.dart';

/// Everything the AI chef can do, wired to the app's cubits so each change
/// goes through the same optimistic, persisted path as a tap would.
class ChatTools {
  ChatTools({
    required this.profile,
    required this.catalogue,
    required this.plan,
    required this.recipes,
    required this.shopping,
    required this.search,
    required this.ai,
    required this.quota,
    required this.analytics,
  });

  final ProfileCubit profile;
  final CatalogueCubit catalogue;
  final PlanCubit plan;
  final RecipeCubit recipes;
  final ShoppingCubit shopping;
  final RecipeSearchService search;
  final RecipeAiService ai;

  /// The user's daily recipe searches, which chat searches spend too.
  final SearchQuotaCubit quota;
  final AnalyticsService analytics;

  late final List<ChatTool> all = [
    ...planTools(this),
    ...recipeTools(this),
    ...preferenceTools(this),
    ...shoppingTools(this),
    ...spoonacularTools(this),
  ];

  late final Map<String, ChatTool> byName = {for (final t in all) t.name: t};

  List<FunctionDeclaration> get declarations => [for (final t in all) t.declaration];

  Store get store => profile.state.profile.store;

  /// A recipe from the app itself: the catalogue or a saved favourite.
  Recipe? known(String id) => catalogue.state.byId(id) ?? recipes.state.savedRecipe(id);

  /// Puts a recipe found or written in the chat into the catalogue, so the
  /// week can use it.
  Future<void> ensureInPool(Recipe recipe) async {
    if (known(recipe.id) == null) await catalogue.addRecipe(recipe);
  }

  /// The week as the model sees it.
  Map<String, Object?> weekJson() =>
      ToolPayloads.week(plan.state.week, store, recipesOutdated: catalogue.state.outdated);

  /// A short, stable reason for a failure, which the model explains to the
  /// user in their language.
  static String reasonFor(Object error) => switch (error) {
    SearchLimitException() || FirebaseFunctionsException(code: 'resource-exhausted') => 'quota_exhausted',
    FirebaseFunctionsException(code: 'invalid-argument') => 'invalid_request',
    FirebaseFunctionsException() => 'recipe_service_unavailable',
    FirebaseAIException() => 'ai_unavailable',
    _ => 'failed',
  };
}
