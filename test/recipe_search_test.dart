import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/catalogue_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_browse_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_search_cubit.dart';
import 'package:tably/features/recipe/cubit/search_quota_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSearch api;

  RecipeSearchCubit cubit({FakeAi? ai, SearchQuotaCubit? quota}) {
    api = FakeSearch();
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    final cubit = RecipeSearchCubit(
      search: api,
      quota: quota ?? unboundQuota(profileCubit),
      ai: ai ?? FakeAi(),
      profileCubit: profileCubit,
      analytics: const AnalyticsService(),
    );
    addTearDown(cubit.close);
    addTearDown(profileCubit.close);
    return cubit;
  }

  test('the pool is twice the recipes the week cooks, never under 24', () {
    int size(int mealsPerDay, Variety variety) =>
        CatalogueCubit.poolSizeFor(UserProfile(mealsPerDay: mealsPerDay, variety: variety));
    expect(size(2, Variety.high), 28, reason: '14 recipes × 2');
    expect(size(1, Variety.high), 24, reason: '7 × 2 = 14, raised to the minimum');
    expect(size(2, Variety.low), 24);
  });

  test('searches 50 recipes with the text in English and the filters', () async {
    final search = cubit();
    const browse = RecipeBrowseState(
      query: ' poulet curry ',
      cuisines: {Cuisine.indian},
      cravings: {Craving.quick},
      proteins: {RecipeProtein.chicken},
    );

    await search.search(browse);

    final call = api.calls.single;
    expect(call.number, 50);
    expect(call.query, 'en:poulet curry');
    expect(call.cuisines, {Cuisine.indian});
    expect(call.craving, Craving.quick);
    expect(call.protein, RecipeProtein.chicken);
    expect(search.state.resultsFor(browse), RecipeFixtures.recipes);
  });

  test('candidates over the price limit at the store never reach Gemini', () async {
    final ai = FakeAi();
    final search = cubit(ai: ai);
    // 4 € at Lidl (×0.975) fits candidates costing 0 to 4 € at the reference.
    await search.search(const RecipeBrowseState(maxPrice: 4));
    expect([for (final r in ai.candidates.single) r['id']], [0, 1, 2, 3, 4]);
  });

  test('several cravings or proteins are left to the local filters', () async {
    final search = cubit();
    await search.search(const RecipeBrowseState(
      cravings: {Craving.quick, Craving.lowCalorie},
      proteins: {RecipeProtein.beef, RecipeProtein.fish},
    ));
    expect(api.calls.single.craving, isNull);
    expect(api.calls.single.protein, isNull);
  });

  test('the same search is not repeated, but reload always calls the API', () async {
    final search = cubit();
    const browse = RecipeBrowseState(query: 'tofu');

    await search.search(browse);
    await search.search(browse);
    expect(api.calls, hasLength(1));

    await search.search(browse, reload: true);
    expect(api.calls, hasLength(2));
  });

  test('results belong to their search; any change shows the pool again', () async {
    final search = cubit();
    await search.search(const RecipeBrowseState(query: 'tofu'));
    expect(search.state.resultsFor(const RecipeBrowseState(query: 'tofu ')), isNull);
    expect(search.state.byId(RecipeFixtures.recipes.first.id), isNotNull, reason: 'still openable');
  });

  test('nothing to search for makes no call and clears the results', () async {
    final search = cubit();
    await search.search(const RecipeBrowseState(query: 'tofu'));
    await search.search(RecipeBrowseState(constraints: RecipeBrowseState.widest));
    expect(api.calls, hasLength(1));
    expect(search.state.results, isEmpty);
    expect(search.state.status, RecipeSearchStatus.idle);
  });

  test('when Gemini keeps nothing, the search is empty rather than failed', () async {
    final search = cubit(ai: FakeAi(recipes: const <Recipe>[]));
    const browse = RecipeBrowseState(query: 'tofu');
    await search.search(browse);
    expect(search.state.resultsFor(browse), isEmpty);
    expect(search.state.error, isNull);
  });
}
