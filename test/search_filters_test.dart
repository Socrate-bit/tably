import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/core/widget/search_field.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/recipe_browse_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_search_cubit.dart';
import 'package:tably/features/recipe/model/dietary_constraints.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const analytics = AnalyticsService();
  const onboarding = UserProfile(
    diets: {Diet.vegetarian},
    allergies: {Allergy.nutFree},
    appliances: {Appliance.hob, Appliance.oven},
  );

  /// A browse cubit following a profile that finished onboarding with [profile].
  Future<(RecipeBrowseCubit, ProfileCubit)> browse(UserProfile profile) async {
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: analytics);
    final cubit = RecipeBrowseCubit(profileCubit: profileCubit, analytics: analytics);
    addTearDown(cubit.close);
    addTearDown(profileCubit.close);
    // A loaded profile still onboarding, as for a new user.
    await profileCubit.setName('');
    await profileCubit.completeOnboarding(profile);
    await Future<void>.delayed(Duration.zero);
    return (cubit, profileCubit);
  }

  group('diets, allergies and appliances in the filters', () {
    test('are seeded from the onboarding answers', () async {
      final (cubit, _) = await browse(onboarding);
      expect(cubit.state.constraints, DietaryConstraints.of(onboarding));
    });

    test('can differ from the profile, which stays untouched', () async {
      final (cubit, profileCubit) = await browse(onboarding);

      cubit.toggleDiet(Diet.vegan);
      cubit.toggleAllergy(Allergy.glutenFree);
      cubit.toggleAppliance(Appliance.oven);

      expect(cubit.state.constraints.diets, {Diet.vegetarian, Diet.vegan});
      expect(cubit.state.constraints.allergies, {Allergy.nutFree, Allergy.glutenFree});
      expect(cubit.state.constraints.appliances, {Appliance.hob});
      expect(cubit.state.canSearch, isTrue);
      expect(profileCubit.state.profile.diets, {Diet.vegetarian});
    });

    test('follow the same selection rules as the preferences', () async {
      final (cubit, _) = await browse(onboarding);

      cubit.toggleDiet(Diet.none);
      expect(cubit.state.constraints.diets, {Diet.none}, reason: '"none" clears the rest');
      cubit.toggleAllergy(Allergy.nutFree);
      expect(cubit.state.constraints.allergies, {Allergy.none}, reason: 'clearing everything falls back to "none"');
      cubit.toggleAppliance(Appliance.hob);
      cubit.toggleAppliance(Appliance.oven);
      expect(cubit.state.constraints.appliances, isEmpty, reason: 'no appliance at all is allowed');
    });

    test('never follow later preference changes', () async {
      final (cubit, profileCubit) = await browse(onboarding);

      await profileCubit.toggleDiet(Diet.vegan);
      await profileCubit.setCookMinutes(30);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.constraints, DietaryConstraints.of(onboarding));
    });

    test('"Réinitialiser" widens everything but keeps the search text', () async {
      final (cubit, _) = await browse(onboarding);
      cubit.search('dahl');
      cubit.toggleDiet(Diet.vegan);
      cubit.toggleCraving(Craving.quick);
      cubit.setCookMinutes(30);

      cubit.resetFilters();

      expect(cubit.state.constraints, RecipeBrowseState.widest);
      expect(cubit.state.filterCount, 0);
      expect(cubit.state.query, 'dahl');
    });

    test('a time limit counts as one filter and hides longer recipes', () async {
      final (cubit, _) = await browse(onboarding);
      cubit.resetFilters();

      cubit.setCookMinutes(20);

      expect(cubit.state.filterCount, 1);
      expect(cubit.state.constraints.applyTo(onboarding).cookMinutes, 20);
      final kept = cubit.state.apply(RecipeFixtures.recipes, store: Store.lidl, cravingLabel: (c) => c.id);
      expect(kept, isNotEmpty);
      expect(kept.every((r) => r.minutes! <= 20), isTrue);
      expect(kept.length, lessThan(RecipeFixtures.recipes.length));
    });
  });

  test('the search and the Gemini check use the filters, not the profile', () async {
    final (browseCubit, profileCubit) = await browse(onboarding);
    final api = FakeSearch();
    final ai = FakeAi();
    final search = RecipeSearchCubit(search: api, ai: ai, profileCubit: profileCubit, analytics: analytics);
    addTearDown(search.close);

    browseCubit.search('curry');
    browseCubit.toggleDiet(Diet.vegan);
    browseCubit.toggleAllergy(Allergy.glutenFree);
    await search.search(browseCubit.state);

    final searched = api.calls.single.profile;
    expect(searched.diets, {Diet.vegetarian, Diet.vegan});
    expect(searched.allergies, {Allergy.nutFree, Allergy.glutenFree});
    expect(searched.appliances, onboarding.appliances);
    expect(ai.checkedFor.single.diets, searched.diets);
    expect(api.calls.single.query, 'en:curry');
  });

  group('the search field', () {
    Future<List<String>> pump(WidgetTester tester, {required ValueNotifier<bool> show}) async {
      final submitted = <String>[];
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(402, 860),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (_, visible, _) => Column(children: [
                if (visible) SearchField(hint: 'search', onChanged: (_) {}, onSubmitted: submitted.add),
                const TextField(key: Key('other')),
              ]),
            ),
          ),
        ),
      ));
      return submitted;
    }

    testWidgets('searches when the user leaves it', (tester) async {
      final submitted = await pump(tester, show: ValueNotifier(true));
      await tester.enterText(find.byType(SearchField), 'poulet');
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();
      expect(submitted, ['poulet']);
    });

    testWidgets('does not search when it disappears while focused', (tester) async {
      final show = ValueNotifier(true);
      final submitted = await pump(tester, show: show);
      await tester.enterText(find.byType(SearchField), 'poulet');
      show.value = false;
      await tester.pump();
      expect(submitted, isEmpty);
    });
  });
}
