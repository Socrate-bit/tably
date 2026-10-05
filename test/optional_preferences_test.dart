import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/util/selection.dart';
import 'package:tably/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:tably/features/onboarding/model/onboarding_step.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('"no meat" stands alone, and nothing at all is allowed', () {
    final none = Selection.toggleExclusive(const {Protein.beef, Protein.fish}, Protein.noMeat, Protein.noMeat);
    expect(none, {Protein.noMeat});
    expect(Selection.toggleExclusive(none, Protein.chicken, Protein.noMeat), {Protein.chicken});
    expect(Selection.toggleExclusive(none, Protein.noMeat, Protein.noMeat), isEmpty);
    expect(Selection.toggleExclusive(const {Protein.beef}, Protein.beef, Protein.noMeat), isEmpty);
  });

  test('preferences let cravings, meats and appliances be emptied', () async {
    final cubit = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    addTearDown(cubit.close);
    await cubit.completeOnboarding(const UserProfile(
      cravings: {Craving.quick},
      proteins: {Protein.beef},
      appliances: {Appliance.hob},
    ));

    await cubit.toggleCraving(Craving.quick);
    await cubit.toggleProtein(Protein.beef);
    await cubit.toggleAppliance(Appliance.hob);

    expect(cubit.state.profile.cravings, isEmpty);
    expect(cubit.state.profile.proteins, isEmpty);
    expect(cubit.state.profile.appliances, isEmpty);

    await cubit.toggleAppliance(Appliance.mixer);
    expect(cubit.state.profile.appliances, {Appliance.mixer});
  });

  test('an emptied choice survives the round trip through Firestore', () {
    const blank = UserProfile(cravings: {}, proteins: {}, appliances: {});
    final read = UserProfile.fromMap(blank.toMap());
    expect(read.cravings, isEmpty);
    expect(read.proteins, isEmpty);
    expect(read.appliances, isEmpty);

    // A profile saved before these fields existed still gets the defaults.
    final legacy = UserProfile.fromMap(blank.toMap()..remove('proteins'));
    expect(legacy.proteins, const UserProfile().proteins);
  });

  test('onboarding continues with nothing picked for cravings, meats and appliances', () {
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    final catalogue = seededCatalogue(profileCubit);
    final cubit = OnboardingCubit(catalogueCubit: catalogue, analytics: const AnalyticsService());
    addTearDown(cubit.close);
    addTearDown(catalogue.close);
    addTearDown(profileCubit.close);
    const draft = UserProfile(cravings: {}, proteins: {}, appliances: {});
    for (final id in [StepIds.cravings, StepIds.proteins, StepIds.appliances]) {
      final index = cubit.state.steps.indexWhere((s) => s.id == id);
      expect(cubit.state.copyWith(stepIndex: index, draft: draft).canContinue, isTrue, reason: id);
    }
  });

  group('what Gemini is told', () {
    String rules(UserProfile profile) => RecipeAiService.instruction(profile);

    test('no meat ticked means any meat; "no meat" means none', () {
      expect(rules(const UserProfile(proteins: {})), contains('Allowed:\n  any meat or fish'));
      expect(rules(const UserProfile(proteins: {Protein.noMeat})), contains('eats no meat or fish at all'));
      expect(rules(const UserProfile(proteins: {Protein.chicken})), contains('Allowed:\n  chicken.'));
    });

    test('no appliance means only no-cook recipes, and the mixer is understood', () {
      expect(rules(const UserProfile(appliances: {})), contains('no cooking appliance at all'));
      final withMixer = rules(const UserProfile(appliances: {Appliance.hob, Appliance.mixer}));
      expect(withMixer, contains('The user has: hob, mixer'));
      expect(withMixer, contains('mixer = blender or food processor'));
    });
  });
}
