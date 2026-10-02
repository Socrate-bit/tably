import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/plan/model/plan_settings.dart';
import 'package:tably/features/plan/model/week_plan.dart';
import 'package:tably/features/plan/service/week_planner.dart';
import 'package:tably/features/preferences/model/user_profile.dart';

import 'fixtures/recipe_fixtures.dart';

UserProfile _profile(int mealsPerDay, List<int> dayIndexes, {Variety variety = Variety.high, int household = 1}) =>
    UserProfile(
      mealsPerDay: mealsPerDay,
      household: household,
      variety: variety,
      days: {for (final i in dayIndexes) Weekday.values[i]},
    );

void main() {
  // Fixtures come from running the design prototype's own algorithm in Node,
  // so this proves the port produces the exact weeks the design shows.
  final cases = jsonDecode(File('test/fixtures/design_plans.json').readAsStringSync()) as List;

  test('matches the design for ${cases.length} one-meal-a-day combinations', () {
    // Only one meal a day with a new dish each night still follows the design;
    // leftovers are now planned from the chosen recipe count.
    for (final c in cases.cast<Map<String, dynamic>>().where((c) => c['perDay'] == 1)) {
      final mealsPerDay = c['perDay'] as int;
      final plan = WeekPlanner.build(
        profile: _profile(mealsPerDay, (c['mask'] as List).cast<int>()),
        settings: PlanSettings(seed: c['seed'] as int),
        catalogue: RecipeFixtures.recipes,
      );
      final slots = MealSlot.forMealsPerDay(mealsPerDay);
      final expected = (c['slots'] as List).cast<Map<String, dynamic>>();

      expect(plan.slots.length, expected.length, reason: 'case $c');
      for (final (i, e) in expected.indexed) {
        final actual = plan.slots[i];
        final where = 'seed ${c['seed']}, perDay $mealsPerDay, slot $i';
        expect(actual.day, Weekday.values[e['day'] as int], reason: where);
        expect(actual.slot, slots[e['slot'] as int], reason: where);
        expect(actual.recipe.title, e['title'], reason: where);
        expect(actual.isLeftover, e['leftover'], reason: where);
      }
    }
  });

  test('the recipe count is exactly what the variety level promises', () {
    for (final (variety, recipes) in [(Variety.high, 14), (Variety.balanced, 7), (Variety.low, 4)]) {
      final plan = WeekPlanner.build(
        profile: _profile(2, [0, 1, 2, 3, 4, 5, 6], variety: variety),
        settings: const PlanSettings(),
        catalogue: RecipeFixtures.recipes,
      );
      expect(plan.slotCount, 14);
      // Every chosen dish is cooked; past the catalogue's size some come back.
      expect(plan.slots.where((s) => !s.isLeftover).length, recipes);
      expect(plan.recipeCount, min(recipes, RecipeFixtures.recipes.length));
    }
  });

  test('one meal a day offers 7, 4 and 2 recipes', () {
    int recipes(Variety v) => _profile(1, [0, 1, 2, 3, 4, 5, 6], variety: v).recipesToCook;
    expect([recipes(Variety.high), recipes(Variety.balanced), recipes(Variety.low)], [7, 4, 2]);
  });

  test('a swapped meal carries through to its leftover', () {
    final profile = _profile(2, [0, 1, 2, 3, 4, 5, 6], variety: Variety.balanced);
    final base = WeekPlanner.build(profile: profile, settings: const PlanSettings(), catalogue: RecipeFixtures.recipes);
    final mondayLunch = base.slotByKey('monday|lunch')!;
    final other = RecipeFixtures.recipes.firstWhere((r) => r.id != mondayLunch.recipe.id);

    final swapped = WeekPlanner.build(
      profile: profile,
      settings: PlanSettings(overrides: {'monday|lunch': other.id}),
      catalogue: RecipeFixtures.recipes,
    );

    expect(swapped.slotByKey('monday|lunch')!.recipe, other);
    final mondayDinner = swapped.slotByKey('monday|dinner')!;
    expect(mondayDinner.isLeftover, isTrue);
    expect(mondayDinner.recipe, other, reason: 'the leftover must be what was cooked');
    expect(swapped.slotByKey('monday|lunch')!.portions, 2, reason: 'the swap is cooked for its leftover too');
  });

  test('a cooked meal pays for every portion of its pot, leftovers are free', () {
    final plan = WeekPlanner.build(
      profile: _profile(2, [0, 1, 2, 3, 4, 5, 6], variety: Variety.balanced, household: 3),
      settings: const PlanSettings(),
      catalogue: RecipeFixtures.recipes,
    );
    expect(plan.slotCount, 14);
    expect(plan.slots.where((s) => s.isLeftover).map((s) => s.portions), everyElement(0));
    expect(plan.slots.fold<int>(0, (t, s) => t + s.portions), 14 * 3, reason: 'every meal eaten is cooked once');
    for (final (i, s) in plan.slots.indexed) {
      if (s.isLeftover) continue;
      final leftovers = plan.slots.skip(i + 1).takeWhile((n) => n.isLeftover).length;
      expect(s.portions, 3 * (1 + leftovers), reason: s.key);
    }
    expect(plan.baseTotal, closeTo(plan.slots.fold<double>(0, (t, s) => t + s.recipe.price * 3), 1e-9));
    expect(plan.totalAt(Store.monoprix), closeTo(plan.baseTotal * 1.15, 1e-9));
  });

  test('an empty week has no slots and costs nothing', () {
    final plan = WeekPlanner.build(profile: _profile(1, []), settings: const PlanSettings(), catalogue: RecipeFixtures.recipes);
    expect(plan.slots, isEmpty);
    expect(plan.baseTotal, 0);
  });
}
