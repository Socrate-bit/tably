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

  test('one meal a day offers 7 and 4 recipes', () {
    // A dinner keeps until the next day's dinner only, so batch cooking can't
    // stretch a pot further than balanced does.
    final profile = _profile(1, [0, 1, 2, 3, 4, 5, 6]);
    int recipes(Variety v) => profile.copyWith(variety: v).recipesToCook;
    expect([recipes(Variety.high), recipes(Variety.balanced), recipes(Variety.low)], [7, 4, 4]);
    expect(profile.varietyRecipes, {Variety.high: 7, Variety.balanced: 4});
  });

  test('leftovers stay fresh and alternate for every week shape', () {
    int hourOf(PlanSlot s) => s.day.index * 24 + s.slot.hour;
    for (var mask = 1; mask < 128; mask++) {
      for (final mealsPerDay in [1, 2]) {
        for (final variety in Variety.values) {
          final profile = _profile(mealsPerDay, [for (var d = 0; d < 7; d++) if (mask & 1 << d != 0) d], variety: variety);
          final plan = WeekPlanner.build(profile: profile, settings: const PlanSettings(), catalogue: RecipeFixtures.recipes);
          final where = 'mask $mask, perDay $mealsPerDay, $variety';

          expect(plan.slots.where((s) => !s.isLeftover).length, profile.recipesToCook, reason: where);
          for (final (i, s) in plan.slots.indexed) {
            if (!s.isLeftover) continue;
            final cooked = plan.slots.take(i).lastWhere((c) => !c.isLeftover && c.recipe.id == s.recipe.id);
            expect(hourOf(s) - hourOf(cooked), lessThanOrEqualTo(UserProfile.leftoverHours), reason: '$where, ${s.key}');
          }
          // A dish only comes back to back inside a window with a single pot.
          final windows = profile.freshWindows;
          for (final window in windows) {
            final slots = [for (final i in window) plan.slots[i]];
            if (slots.where((s) => !s.isLeftover).length < 2) continue;
            for (var j = 1; j < slots.length; j++) {
              expect(slots[j].recipe.id, isNot(slots[j - 1].recipe.id), reason: '$where, ${slots[j].key}');
            }
          }
        }
      }
    }
  });

  test('two meals a day on balanced alternates dishes across each pair of days', () {
    final plan = WeekPlanner.build(
      profile: _profile(2, [0, 1, 2, 3, 4, 5, 6], variety: Variety.balanced),
      settings: const PlanSettings(),
      catalogue: RecipeFixtures.recipes,
    );
    final ids = plan.slots.map((s) => s.recipe.id).toList();
    // Monday and Tuesday: A B A B.
    expect([ids[2], ids[3]], [ids[0], ids[1]]);
    expect(ids[0], isNot(ids[1]));
    expect([for (final s in plan.slots.take(4)) s.isLeftover], [false, false, true, true]);
    // Sunday stands alone, so its dinner is the only back-to-back repeat.
    final repeats = [for (var i = 1; i < ids.length; i++) if (ids[i] == ids[i - 1]) plan.slots[i].key];
    expect(repeats, ['sunday|dinner']);
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
    final tuesdayLunch = swapped.slotByKey('tuesday|lunch')!;
    expect(tuesdayLunch.isLeftover, isTrue);
    expect(tuesdayLunch.recipe, other, reason: 'the leftover must be what was cooked');
    expect(swapped.slotByKey('monday|lunch')!.portions, 2, reason: 'the swap is cooked for its leftover too');
  });

  test('a moved meal keeps its dish, and its pot is cooked wherever it now comes first', () {
    final profile = _profile(2, [0, 1, 2, 3, 4, 5, 6], variety: Variety.balanced);
    final base = WeekPlanner.build(profile: profile, settings: const PlanSettings(), catalogue: RecipeFixtures.recipes);
    final keys = [for (final s in base.slots) s.key];
    expect(base.slotByKey('tuesday|lunch')!.isLeftover, isTrue);

    // Drag Tuesday's leftover lunch to the top of the week.
    final order = ['tuesday|lunch', ...keys.where((k) => k != 'tuesday|lunch')];
    final moved = WeekPlanner.build(profile: profile, settings: PlanSettings(order: order), catalogue: RecipeFixtures.recipes);

    expect([for (final s in moved.slots) s.key], order);
    final first = moved.slots.first;
    expect((first.day, first.slot), (Weekday.monday, MealSlot.lunch), reason: 'it shows at the first place');
    expect(first.recipe, base.slotByKey('tuesday|lunch')!.recipe);
    expect(first.isLeftover, isFalse, reason: 'it now comes first, so its pot is cooked here');
    expect(first.portions, 2);
    final second = moved.slots[1];
    expect(second.key, 'monday|lunch');
    expect((second.day, second.slot), (Weekday.monday, MealSlot.dinner));
    expect(second.isLeftover, isTrue);
    expect(moved.baseTotal, closeTo(base.baseTotal, 1e-9), reason: 'moving meals never changes what is bought');
  });

  test('an order that no longer matches the week is ignored', () {
    final profile = _profile(1, [0, 1, 2]);
    final base = WeekPlanner.build(profile: profile, settings: const PlanSettings(), catalogue: RecipeFixtures.recipes);
    final stale = WeekPlanner.build(
      profile: profile,
      settings: const PlanSettings(order: ['friday|dinner', 'monday|dinner', 'tuesday|dinner']),
      catalogue: RecipeFixtures.recipes,
    );
    expect(stale, base);
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
      final leftovers = plan.slots.skip(i + 1).where((n) => n.isLeftover && n.recipe.id == s.recipe.id).length;
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
