import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/plan/model/plan_settings.dart';
import 'package:tably/features/plan/model/week_plan.dart';
import 'package:tably/features/plan/service/week_planner.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/service/recipe_catalogue.dart';

UserProfile _profile(int mealsPerDay, List<int> dayIndexes) => UserProfile(
      mealsPerDay: mealsPerDay,
      days: {for (final i in dayIndexes) Weekday.values[i]},
    );

void main() {
  // Fixtures come from running the design prototype's own algorithm in Node,
  // so this proves the port produces the exact weeks the design shows.
  final cases = jsonDecode(File('test/fixtures/design_plans.json').readAsStringSync()) as List;

  test('matches the design for ${cases.length} seed/meals/day combinations', () {
    for (final c in cases.cast<Map<String, dynamic>>()) {
      final mealsPerDay = c['perDay'] as int;
      final plan = WeekPlanner.build(
        profile: _profile(mealsPerDay, (c['mask'] as List).cast<int>()),
        settings: PlanSettings(seed: c['seed'] as int),
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

  test('a swapped meal carries through to its leftover', () {
    final profile = _profile(2, [0, 1, 2, 3, 4, 5, 6]);
    final base = WeekPlanner.build(profile: profile, settings: const PlanSettings());
    final mondayLunch = base.slotByKey('monday|lunch')!;
    final other = RecipeCatalogue.recipes.firstWhere((r) => r.id != mondayLunch.recipe.id);

    final swapped = WeekPlanner.build(
      profile: profile,
      settings: PlanSettings(overrides: {'monday|lunch': other.id}),
    );

    expect(swapped.slotByKey('monday|lunch')!.recipe, other);
    final tuesdayLunch = swapped.slotByKey('tuesday|lunch')!;
    expect(tuesdayLunch.isLeftover, isTrue);
    expect(tuesdayLunch.recipe, other, reason: 'the leftover must be what was cooked');
  });

  test('leftovers are free and counted once in the recipe total', () {
    final plan = WeekPlanner.build(
      profile: _profile(2, [0, 1, 2, 3, 4, 5, 6]),
      settings: const PlanSettings(),
    );
    final cooked = plan.slots.where((s) => !s.isLeftover);
    expect(plan.slotCount, 14);
    expect(plan.baseTotal, closeTo(cooked.fold<double>(0, (t, s) => t + s.recipe.price), 1e-9));
    expect(plan.totalAt(Store.monoprix), closeTo(plan.baseTotal * 1.21, 1e-9));
  });

  test('an empty week has no slots and costs nothing', () {
    final plan = WeekPlanner.build(profile: _profile(1, []), settings: const PlanSettings());
    expect(plan.slots, isEmpty);
    expect(plan.baseTotal, 0);
  });
}
