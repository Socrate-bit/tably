import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/chat/model/preference_change.dart';
import 'package:tably/features/preferences/model/user_profile.dart';

void main() {
  const profile = UserProfile(diets: {Diet.vegetarian}, cravings: {Craving.quick});

  test('lists are set whole and the change lists what was added and removed', () {
    final change = PreferenceChange.of(profile, {
      'diets': ['vegan'],
      'household': 4,
      'days': ['monday', 'friday'],
    });

    expect(change.error, isNull);
    expect(change.next.diets, {Diet.vegan});
    expect(change.next.household, 4);
    expect(change.next.days, {Weekday.monday, Weekday.friday});
    expect(change.changes['diets'], {'added': ['vegan'], 'removed': ['vegetarian']});
    expect(change.changes['household'], {'from': 1, 'to': 4});
    expect(change.changes.containsKey('cravings'), isFalse);
  });

  test('"none" stands alone and fills an empty choice, as on the screen', () {
    expect(PreferenceChange.of(profile, {'diets': <String>[]}).next.diets, {Diet.none});
    expect(PreferenceChange.of(profile, {'diets': ['none', 'halal']}).next.diets, {Diet.halal});
    expect(PreferenceChange.of(profile, {'allergies': ['none']}).next.allergies, {Allergy.none});
  });

  test('changes the screen would not allow are refused with a reason', () {
    expect(PreferenceChange.of(profile, {'cravings': ['quick', 'indulgent', 'fakeaway', 'low_calorie']}).error, contains('three'));
    expect(PreferenceChange.of(profile, {'proteins': ['no_meat', 'beef']}).error, contains('no_meat'));
    expect(PreferenceChange.of(profile, {'days': <String>[]}).error, contains('day'));
    expect(PreferenceChange.of(profile, {'household': 40}).error, contains('household'));
    expect(PreferenceChange.of(profile, {'diets': ['carnivore']}).error, contains('carnivore'));
    expect(PreferenceChange.of(profile, {'language': 'de'}).error, contains('language'));
  });

  test('custom instructions and the time limit are set as on the screen', () {
    final change = PreferenceChange.of(profile, {'custom_instructions': '  pas de coriandre ', 'cook_minutes': 30});
    expect(change.next.customInstructions, 'pas de coriandre');
    expect(change.next.cookMinutes, 30);
    expect(change.changes['custom_instructions'], {'from': '', 'to': 'pas de coriandre'});

    expect(PreferenceChange.of(profile, {'custom_instructions': 'x' * 301}).error, isNotNull);
    expect(PreferenceChange.of(profile, {'cook_minutes': 5}).error, contains('cook_minutes'));
  });

  test('nothing to change gives no changes', () {
    expect(PreferenceChange.of(profile, {'diets': ['vegetarian']}).changes, isEmpty);
  });
}
