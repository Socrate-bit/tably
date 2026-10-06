import 'dart:async';

import 'package:flutter_test/flutter_test.dart' show pumpEventQueue;
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/features/chat/cubit/chat_cubit.dart';
import 'package:tably/features/chat/service/chat_agent_service.dart';
import 'package:tably/features/chat/service/chat_service.dart';
import 'package:tably/features/chat/tool/chat_tools.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/plan/model/plan_settings.dart';
import 'package:tably/features/plan/service/plan_service.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/catalogue_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/cubit/search_quota_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';
import 'package:tably/features/recipe/service/recipe_search_service.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';
import 'package:tably/features/shopping/cubit/shopping_cubit.dart';
import 'package:tably/features/shopping/model/shopping_item.dart';
import 'package:tably/features/shopping/service/shopping_ai_service.dart';
import 'package:tably/features/shopping/service/shopping_service.dart';

import 'recipe_fixtures.dart';

/// Keeps the week in memory instead of Firestore.
class FakePlanService extends PlanService {
  @override
  Stream<PlanSettings> watch(String uid) => Stream.value(const PlanSettings());

  @override
  Future<void> save(String uid, PlanSettings settings) async {}
}

/// Keeps the catalogue in memory instead of Firestore, built for [key] and
/// ordered by id as Firestore serves it, so the cubit flags it outdated
/// after a preferences change as in the app.
class FakeRecipeService extends RecipeService {
  FakeRecipeService(List<Recipe> recipes, {required String key})
    : _recipes = {for (final r in recipes) r.id: r},
      _keys = (key: key, keptKey: null);

  final Map<String, Recipe> _recipes;
  ({String? key, String? keptKey}) _keys;
  final _recipeEvents = StreamController<List<Recipe>>.broadcast();
  final _keyEvents = StreamController<({String? key, String? keptKey})>.broadcast();

  List<Recipe> get _sorted => _recipes.values.toList()..sort((a, b) => a.id.compareTo(b.id));

  @override
  Stream<List<Recipe>> watchCatalogue(String uid) async* {
    yield _sorted;
    yield* _recipeEvents.stream;
  }

  @override
  Stream<({String? key, String? keptKey})> watchCatalogueKeys(String uid) async* {
    yield _keys;
    yield* _keyEvents.stream;
  }

  @override
  Future<void> keepCatalogue(String uid, String keptKey) async =>
      _keyEvents.add(_keys = (key: _keys.key, keptKey: keptKey));

  @override
  Future<void> saveRecipe(String uid, Recipe recipe) async {
    _recipes[recipe.id] = recipe;
    _recipeEvents.add(_sorted);
  }

  /// Like Firestore's: the user's own recipes stay.
  @override
  Future<void> replaceCatalogue(String uid, List<Recipe> recipes, String key) async {
    _recipes
      ..removeWhere((_, r) => r.origin != RecipeOrigin.chef)
      ..addAll({for (final r in recipes) r.id: r});
    _recipeEvents.add(_sorted);
    _keyEvents.add(_keys = (key: key, keptKey: null));
  }
}

/// Starts with an empty shopping list and keeps writes in memory.
class FakeShoppingService extends ShoppingService {
  @override
  Stream<List<ShoppingItem>> watch(String uid) => Stream.value(const []);

  @override
  Future<void> replaceList(String uid, List<ShoppingItem> items, Iterable<String> removedIds) async {}
}

/// Merges nothing, so each ingredient line is its own item.
class FakeShoppingAi extends ShoppingAiService {
  @override
  Future<List<ShoppingItem>> aggregate(List<Ingredient> lines, String languageCode, String source) async =>
      ShoppingAiService.merge(lines, const {}, source);
}

/// The AI chef wired to the app's real cubits and tools over the fixtures,
/// talking to [agent]. Nothing reaches Firestore or Spoonacular.
class ChatHarness {
  ChatHarness._({
    required this.profile,
    required this.catalogue,
    required this.plan,
    required this.recipes,
    required this.shopping,
    required this.quota,
    required this.tools,
    required this.chat,
  });

  final ProfileCubit profile;
  final CatalogueCubit catalogue;
  final PlanCubit plan;
  final RecipeCubit recipes;
  final ShoppingCubit shopping;
  final SearchQuotaCubit quota;
  final ChatTools tools;
  final ChatCubit chat;

  /// Onboards [user] (2 people by default) and builds the week and its
  /// shopping list, with [searchesUsed] of today's searches spent.
  static Future<ChatHarness> start(
    ChatAgentService agent, {
    UserProfile user = const UserProfile(household: 2),
    int searchesUsed = 0,
    RecipeSearchService? search,
    RecipeAiService? ai,
  }) async {
    const analytics = AnalyticsService();
    search ??= FakeSearch();
    ai ??= FakeAi();
    final profile = ProfileCubit(service: ProfileService(), analytics: analytics);
    final quota = searchesUsed == 0 ? unboundQuota(profile) : await spentQuota(profile, used: searchesUsed);
    final catalogue = CatalogueCubit(
      service: FakeRecipeService(
        RecipeFixtures.recipes,
        key: CatalogueCubit.keyFor(user.copyWith(onboardingComplete: true)),
      ),
      search: search,
      quota: quota,
      ai: ai,
      profileCubit: profile,
      analytics: analytics,
    );
    final recipes = RecipeCubit(service: RecipeService(), analytics: analytics);
    final plan = PlanCubit(
      service: FakePlanService(),
      profileCubit: profile,
      catalogueCubit: catalogue,
      recipeCubit: recipes,
      analytics: analytics,
    );
    final shopping = ShoppingCubit(
      service: FakeShoppingService(),
      ai: FakeShoppingAi(),
      planCubit: plan,
      profileCubit: profile,
      analytics: analytics,
    );
    final tools = ChatTools(
      profile: profile,
      catalogue: catalogue,
      plan: plan,
      recipes: recipes,
      shopping: shopping,
      search: search,
      ai: ai,
      quota: quota,
      analytics: analytics,
    );
    final chat = ChatCubit(service: ChatService(), agent: agent, tools: tools, analytics: analytics);
    await profile.completeOnboarding(user);
    catalogue.bind('u');
    plan.bind('u');
    shopping.bind('u');
    await pumpEventQueue();
    return ChatHarness._(
      profile: profile,
      catalogue: catalogue,
      plan: plan,
      recipes: recipes,
      shopping: shopping,
      quota: quota,
      tools: tools,
      chat: chat,
    );
  }

  Future<void> close() async {
    for (final c in [chat, shopping, plan, recipes, catalogue, quota, profile]) {
      await c.close();
    }
  }
}
