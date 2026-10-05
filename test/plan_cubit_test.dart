import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/plan/service/plan_service.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PlanCubit> build(UserProfile profile, {FakeSearch? search, FakeAi? ai}) async {
    const analytics = AnalyticsService();
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: analytics);
    final catalogue = seededCatalogue(profileCubit, search: search, ai: ai);
    final recipes = RecipeCubit(service: RecipeService(), analytics: analytics);
    final plan = PlanCubit(
      service: PlanService(),
      profileCubit: profileCubit,
      catalogueCubit: catalogue,
      recipeCubit: recipes,
      analytics: analytics,
    );
    addTearDown(plan.close);
    addTearDown(recipes.close);
    addTearDown(catalogue.close);
    addTearDown(profileCubit.close);
    await profileCubit.completeOnboarding(profile);
    await Future<void>.delayed(Duration.zero);
    return plan;
  }

  test('replacing a slot changes only that meal and its leftover', () async {
    final plan = await build(const UserProfile(mealsPerDay: 2, variety: Variety.balanced));
    final before = plan.state.week;
    final lunch = before.slotByKey('monday|lunch')!;
    final other = RecipeFixtures.recipes.firstWhere((r) => before.slots.every((s) => s.recipe.id != r.id));

    await plan.replace('monday|lunch', other.id);

    final after = plan.state.week;
    expect(after.slotByKey('monday|lunch')!.recipe, other);
    expect(after.slotByKey('tuesday|lunch')!.recipe, other, reason: 'leftover follows the swap');
    expect(after.slotByKey('monday|dinner'), before.slotByKey('monday|dinner'));
    expect(lunch.recipe, isNot(other));
  });

  test('reordering moves meals and keeps each one reachable by its key', () async {
    final plan = await build(const UserProfile());
    final before = plan.state.week;
    final keys = [for (final s in before.slots) s.key];

    await plan.reorder([...keys.skip(1), keys.first]);

    final after = plan.state.week;
    expect(after.slots.last.key, 'monday|dinner');
    expect(after.slots.last.day, Weekday.sunday);
    expect(after.slotByKey('monday|dinner')!.recipe, before.slotByKey('monday|dinner')!.recipe);
    expect(after.slots.first.recipe, before.slotByKey('tuesday|dinner')!.recipe);
  });

  test('adding a recipe to the week takes the place of a chosen dish everywhere', () async {
    final plan = await build(const UserProfile(mealsPerDay: 2, variety: Variety.balanced));
    final week = plan.state.week;
    final replaced = week.slots.firstWhere((s) => !s.isLeftover).recipe;
    final incoming = RecipeFixtures.recipes.firstWhere((r) => r.id != replaced.id);

    await plan.replaceRecipe(replaced.id, incoming.id);

    expect(plan.state.week.slots.where((s) => s.recipe.id == replaced.id), isEmpty);
  });

  test('regenerating a meal swaps in a dish not already in the week', () async {
    final search = FakeSearch();
    final plan = await build(const UserProfile(mealsPerDay: 2, variety: Variety.balanced), search: search);
    final before = plan.state.week;
    final inWeek = before.slots.map((s) => s.recipe.id).toSet();

    final next = await plan.regenerateMeal(before.slotByKey('monday|lunch')!);

    expect(next, isNotNull);
    expect(inWeek, isNot(contains(next!.recipe.id)));
    expect(plan.state.week.slotByKey('tuesday|lunch')!.recipe, next.recipe, reason: 'leftover follows the swap');
    expect(plan.state.week.slotByKey('monday|dinner'), before.slotByKey('monday|dinner'));
    expect(search.calls, isEmpty, reason: 'one meal comes from the cached pool, never the API');
  });

  test('regenerating everything fetches a fresh pool sized to the week', () async {
    final search = FakeSearch();
    // Lunch and dinner every day with a new dish each time: 14 recipes, ×2.
    final plan = await build(const UserProfile(mealsPerDay: 2, variety: Variety.high), search: search);

    await plan.regenerate();

    expect(search.calls.single.number, 28);
    expect(search.calls.single.query, isNull, reason: 'the pool is built from the profile alone');
  });

  test('a failed regeneration keeps the current week', () async {
    final plan = await build(const UserProfile(), ai: FakeAi(recipes: const []));
    await plan.replace('monday|dinner', RecipeFixtures.recipes.last.id);
    final before = plan.state;

    await plan.regenerate();

    expect(plan.state.settings, before.settings);
    expect(plan.state.week, before.week);
    expect(plan.state.regenerating, isFalse);
  });

  test('regenerating reshuffles the week and clears swaps', () async {
    final plan = await build(const UserProfile());
    await plan.replace('monday|dinner', RecipeFixtures.recipes.last.id);
    final seed = plan.state.settings.seed;

    await plan.regenerate();

    expect(plan.state.settings.seed, seed + 1);
    expect(plan.state.settings.overrides, isEmpty);
    expect(plan.state.regenerating, isFalse);
  });
}
