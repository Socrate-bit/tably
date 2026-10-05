import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/catalogue_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';

import 'fixtures/recipe_fixtures.dart';

/// Serves the fixtures as the stored catalogue, with keys pushed by the test.
class _FakeRecipeService extends RecipeService {
  final keys = StreamController<({String? key, String? keptKey})>();
  String? kept;

  @override
  Stream<List<Recipe>> watchCatalogue(String uid) => Stream.value(RecipeFixtures.recipes);

  @override
  Stream<({String? key, String? keptKey})> watchCatalogueKeys(String uid) => keys.stream;

  @override
  Future<void> keepCatalogue(String uid, String keptKey) async => kept = keptKey;

  @override
  Future<void> replaceCatalogue(String uid, List<Recipe> recipes, String key) async {}
}

void main() {
  const base = UserProfile(diets: {Diet.vegetarian}, allergies: {Allergy.nutFree, Allergy.eggFree});

  test('the catalogue key ignores what only changes the plan', () {
    final key = CatalogueCubit.keyFor(base);
    expect(
      CatalogueCubit.keyFor(base.copyWith(household: 5, days: {Weekday.monday}, store: Store.aldi, budget: 150)),
      key,
    );
    expect(
      CatalogueCubit.keyFor(base.copyWith(allergies: {Allergy.eggFree, Allergy.nutFree})),
      key,
      reason: 'selection order does not matter',
    );
  });

  test('the catalogue key changes with anything the recipes depend on', () {
    final key = CatalogueCubit.keyFor(base);
    expect(CatalogueCubit.keyFor(base.copyWith(diets: {Diet.vegan})), isNot(key));
    expect(CatalogueCubit.keyFor(base.copyWith(languageCode: 'en')), isNot(key));
    expect(CatalogueCubit.keyFor(base.copyWith(appliances: {Appliance.oven})), isNot(key));
    expect(CatalogueCubit.keyFor(base.copyWith(cookTime: '15_30')), isNot(key));
    expect(CatalogueCubit.keyFor(base.copyWith(proteins: {Protein.fish})), isNot(key));
  });

  test('failures map to reasons the UI and analytics can tell apart', () {
    expect(CatalogueCubit.reasonFor(const NoMatchingRecipesException(12)), 'no_match');
    expect(CatalogueCubit.reasonFor(StateError('x')), 'other');
  });

  group('a preferences change', () {
    late ProfileCubit profile;
    late _FakeRecipeService service;
    late FakeSearch search;
    late CatalogueCubit catalogue;

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() async {
      profile = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
      service = _FakeRecipeService();
      search = FakeSearch();
      catalogue = CatalogueCubit(
        service: service,
        search: search,
        ai: FakeAi(),
        profileCubit: profile,
        analytics: const AnalyticsService(),
      );
      addTearDown(profile.close);
      addTearDown(catalogue.close);
      await profile.completeOnboarding(base);
      catalogue.bind('uid');
      await settle();
    });

    test('builds the first catalogue straight away', () async {
      service.keys.add((key: null, keptKey: null));
      await settle();
      expect(search.calls, hasLength(1));
    });

    test('asks instead of rebuilding, and only for what the recipes depend on', () async {
      service.keys.add((key: CatalogueCubit.keyFor(profile.state.profile), keptKey: null));
      await settle();
      expect(catalogue.state.outdated, isFalse);

      await profile.setMealsPerDay(2);
      await settle();
      expect(catalogue.state.outdated, isFalse, reason: 'meals per day only changes the plan');

      await profile.toggleDiet(Diet.vegan);
      await settle();
      expect(catalogue.state.outdated, isTrue);
      expect(search.calls, isEmpty, reason: 'nothing is fetched until the user chooses');

      await profile.toggleDiet(Diet.vegan);
      await settle();
      expect(catalogue.state.outdated, isFalse, reason: 'back to what the recipes were built for');
    });

    test('keeping the week is remembered until the preferences change again', () async {
      service.keys.add((key: CatalogueCubit.keyFor(profile.state.profile), keptKey: null));
      await profile.toggleDiet(Diet.vegan);
      await settle();

      await catalogue.keep();
      expect(catalogue.state.outdated, isFalse);
      expect(service.kept, CatalogueCubit.keyFor(profile.state.profile));

      await profile.toggleAllergy(Allergy.eggFree);
      await settle();
      expect(catalogue.state.outdated, isTrue);
    });

    test('regenerating rebuilds the recipes and clears the question', () async {
      service.keys.add((key: CatalogueCubit.keyFor(profile.state.profile), keptKey: null));
      await profile.toggleDiet(Diet.vegan);
      await settle();

      expect(await catalogue.build(profile.state.profile), isTrue);
      expect(catalogue.state.outdated, isFalse);
      expect(search.calls, hasLength(1));
    });
  });

  test("the user's own rules change the key only once there are some", () {
    final key = CatalogueCubit.keyFor(base);
    expect(CatalogueCubit.keyFor(base.copyWith(customPreferences: [])), key, reason: 'old catalogues stay current');
    final withRule = CatalogueCubit.keyFor(base.copyWith(customPreferences: ['Pas de coriandre']));
    expect(withRule, isNot(key));
    expect(CatalogueCubit.keyFor(base.copyWith(customPreferences: [' pas de coriandre'])), withRule);
  });

  test("a rebuild keeps the chef's recipes and drops the rest", () async {
    final profile = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    final catalogue = seededCatalogue(profile, ai: FakeAi(recipes: RecipeFixtures.recipes.take(3).toList()));
    addTearDown(profile.close);
    addTearDown(catalogue.close);
    final mine = RecipeFixtures.recipes.last.withOrigin(RecipeOrigin.chef);
    await catalogue.addRecipe(Recipe.fromMap('custom_1', mine.toMap()));

    expect(await catalogue.build(base), isTrue);

    expect(catalogue.state.recipes.map((r) => r.id), containsAll(['custom_1', ...RecipeFixtures.recipes.take(3).map((r) => r.id)]));
    expect(catalogue.state.recipes, hasLength(4));
  });
}
