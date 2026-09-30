import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/plan/model/plan_settings.dart';
import 'package:tably/features/plan/service/week_planner.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/model/recipe_interaction.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final recipes = RecipeFixtures.recipes;
  final catalogue = recipes.take(5).toList();
  // A favourite from an earlier catalogue, since rebuilt without it.
  final gone = recipes.last;

  RecipeCubit cubit() {
    final c = RecipeCubit(service: RecipeService(), analytics: const AnalyticsService());
    addTearDown(c.close);
    return c;
  }

  test('favouriting saves a copy and unfavouriting drops it', () async {
    final recipeCubit = cubit();

    await recipeCubit.toggleFavourite(gone);
    expect(recipeCubit.state.interactionFor(gone.id).recipe, gone);
    expect(recipeCubit.state.savedRecipe(gone.id), gone);

    await recipeCubit.toggleFavourite(gone);
    expect(recipeCubit.state.interactionFor(gone.id).favourite, isFalse);
    expect(recipeCubit.state.interactionFor(gone.id).recipe, isNull);
    expect(recipeCubit.state.savedRecipe(gone.id), isNull);
  });

  test('the saved copy survives a Firestore round trip, and clears on unfavourite', () {
    final saved = RecipeInteraction(recipeId: gone.id, favourite: true, recipe: gone);
    expect(RecipeInteraction.fromMap(gone.id, saved.toMap()), saved);

    final cleared = saved.copyWith(favourite: false, clearRecipe: true).toMap();
    expect(cleared.containsKey('recipe'), isTrue, reason: 'written as null so the merge removes it');
    expect(cleared['recipe'], isNull);
  });

  test('favourites outlive the catalogue and prefer its fresher copy', () async {
    final recipeCubit = cubit();
    final kept = catalogue.first;
    await recipeCubit.toggleFavourite(gone);
    await recipeCubit.toggleFavourite(kept);

    final favourites = recipeCubit.state.favouritesIn(catalogue);
    expect(favourites.map((r) => r.id), unorderedEquals([gone.id, kept.id]));
    expect(identical(favourites.firstWhere((r) => r.id == kept.id), kept), isTrue);
  });

  group('the planner and saved favourites', () {
    final profile = UserProfile(days: {Weekday.monday, Weekday.tuesday, Weekday.wednesday});

    test('never picks a favourite on its own', () {
      for (var seed = 0; seed < 20; seed++) {
        final week = WeekPlanner.build(
          profile: profile,
          settings: PlanSettings(seed: seed),
          catalogue: catalogue,
          favourites: [gone],
        );
        expect(week.slots.map((s) => s.recipe.id), isNot(contains(gone.id)), reason: 'seed $seed');
      }
    });

    test('places a favourite the user swapped in, even outside the catalogue', () {
      final week = WeekPlanner.build(
        profile: profile,
        settings: PlanSettings(overrides: {'tuesday|dinner': gone.id}),
        catalogue: catalogue,
        favourites: [gone],
      );
      expect(week.slotByKey('tuesday|dinner')!.recipe, gone);
    });
  });
}
