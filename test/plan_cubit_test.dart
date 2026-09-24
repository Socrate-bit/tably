import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/plan/service/plan_service.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/service/recipe_catalogue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PlanCubit> build(UserProfile profile) async {
    const analytics = AnalyticsService();
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: analytics);
    final plan = PlanCubit(service: PlanService(), profileCubit: profileCubit, analytics: analytics);
    addTearDown(plan.close);
    addTearDown(profileCubit.close);
    await profileCubit.completeOnboarding(profile);
    await Future<void>.delayed(Duration.zero);
    return plan;
  }

  test('replacing a slot changes only that meal and its leftover', () async {
    final plan = await build(const UserProfile(mealsPerDay: 2));
    final before = plan.state.week;
    final lunch = before.slotByKey('monday|lunch')!;
    final other = RecipeCatalogue.recipes.firstWhere((r) => before.slots.every((s) => s.recipe.id != r.id));

    await plan.replace('monday|lunch', other.id);

    final after = plan.state.week;
    expect(after.slotByKey('monday|lunch')!.recipe, other);
    expect(after.slotByKey('tuesday|lunch')!.recipe, other, reason: 'leftover follows the swap');
    expect(after.slotByKey('monday|dinner'), before.slotByKey('monday|dinner'));
    expect(lunch.recipe, isNot(other));
  });

  test('adding a recipe to the week takes the place of a chosen dish everywhere', () async {
    final plan = await build(const UserProfile(mealsPerDay: 3));
    final week = plan.state.week;
    final replaced = week.slots.firstWhere((s) => !s.isLeftover).recipe;
    final incoming = RecipeCatalogue.recipes.firstWhere((r) => r.id != replaced.id);

    await plan.replaceRecipe(replaced.id, incoming.id);

    expect(plan.state.week.slots.where((s) => s.recipe.id == replaced.id), isEmpty);
  });

  test('regenerating reshuffles the week and clears swaps', () async {
    final plan = await build(const UserProfile());
    await plan.replace('monday|dinner', RecipeCatalogue.recipes.last.id);
    final seed = plan.state.settings.seed;

    await plan.regenerate();

    expect(plan.state.settings.seed, seed + 1);
    expect(plan.state.settings.overrides, isEmpty);
    expect(plan.state.regenerating, isFalse);
  });
}
