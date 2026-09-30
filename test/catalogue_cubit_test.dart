import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/cubit/catalogue_cubit.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';

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
}
