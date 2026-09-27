import '../../features/plan/model/week_plan.dart';
import '../../features/recipe/model/recipe.dart';
import '../../l10n/app_localizations.dart';
import '../model/preference_option.dart';
import '../model/weekday.dart';

/// Resolves the persisted option ids to localised labels. Keeping this in one
/// place means the stored profile never contains display text.
extension OptionLabels on AppL10n {
  String optionLabel(String id) => switch (id) {
        // Survey answers
        'under_24' => ageUnder24,
        '25_34' => age25to34,
        '35_44' => age35to44,
        '45_54' => age45to54,
        '55_plus' => age55plus,
        'meal_prep' => goalMealPrep,
        'simple_recipes' => goalSimpleRecipes,
        'tasty_recipes' => goalTastyRecipes,
        'feed_myself' => goalFeedMyself,
        'feed_family' => goalFeedFamily,
        'no_time' => blockerNoTime,
        'tired' => blockerTired,
        'hard' => blockerHard,
        'no_inspiration' => blockerNoInspiration,
        'saving' => blockerSaving,
        '15_30' => cookTime15to30,
        '30_45' => cookTime30to45,
        '45_60' => cookTime45to60,
        '60_plus' => cookTime60plus,
        // Countries
        'united_states' => countryUs,
        'europe' => countryEurope,
        'united_kingdom' => countryUk,
        'australia' => countryAustralia,
        'canada' => countryCanada,
        'new_zealand' => countryNewZealand,
        'brazil' => countryBrazil,
        'germany' => countryGermany,
        'ireland' => countryIreland,
        'sweden' => countrySweden,
        'netherlands' => countryNetherlands,
        'france' => countryFrance,
        'spain' => countrySpain,
        'rest_of_europe' => countryRestOfEurope,
        // Preferences
        'none' => optionNone,
        'quick' => cravingQuick,
        'high_protein' => cravingHighProtein,
        'low_calorie' => cravingLowCalorie,
        'family_favourites' => cravingFamilyFavourites,
        'healthy_comfort' => cravingHealthyComfort,
        'fakeaway' => cravingFakeaway,
        'easy_digestion' => cravingEasyDigestion,
        'indulgent' => cravingIndulgent,
        'vegetarian' => dietVegetarian,
        'vegan' => dietVegan,
        'pescatarian' => dietPescatarian,
        'halal' => dietHalal,
        'gluten_free' => allergyGlutenFree,
        'lactose_free' => allergyLactoseFree,
        'nut_free' => allergyNutFree,
        'egg_free' => allergyEggFree,
        'shellfish_free' => allergyShellfishFree,
        'sesame_free' => allergySesameFree,
        'soy_free' => allergySoyFree,
        'beef' => proteinBeef,
        'pork' => proteinPork,
        'chicken' => proteinChicken,
        'fish' => proteinFish,
        'tofu' => proteinTofu,
        'microwave' => applianceMicrowave,
        'hob' => applianceHob,
        'oven' => applianceOven,
        'air_fryer' => applianceAirFryer,
        _ => id,
      };

  String dayName(Weekday day) => switch (day) {
        Weekday.monday => dayMonday,
        Weekday.tuesday => dayTuesday,
        Weekday.wednesday => dayWednesday,
        Weekday.thursday => dayThursday,
        Weekday.friday => dayFriday,
        Weekday.saturday => daySaturday,
        Weekday.sunday => daySunday,
      };

  String dayShort(Weekday day) => switch (day) {
        Weekday.monday => dayShortMonday,
        Weekday.tuesday => dayShortTuesday,
        Weekday.wednesday => dayShortWednesday,
        Weekday.thursday => dayShortThursday,
        Weekday.friday => dayShortFriday,
        Weekday.saturday => dayShortSaturday,
        Weekday.sunday => dayShortSunday,
      };

  /// Label for a recipe's badge.
  String cravingLabel(Craving craving) => optionLabel(craving.id);

  String slotName(MealSlot slot) => switch (slot) {
        MealSlot.lunch => slotLunch,
        MealSlot.dinner => slotDinner,
      };

  String varietyName(Variety variety) => switch (variety) {
        Variety.high => varietyHigh,
        Variety.balanced => varietyBalanced,
        Variety.low => varietyLow,
      };

  /// The line under each meals-per-day option.
  String mealsPerDayDetail(int mealsPerDay) => mealsPerDay == 1 ? mealsPerDayDinnerOnly : mealsPerDayLunchDinner;

  String cuisineName(Cuisine cuisine) => switch (cuisine) {
        Cuisine.italian => cuisineItalian,
        Cuisine.asian => cuisineAsian,
        Cuisine.mexican => cuisineMexican,
        Cuisine.indian => cuisineIndian,
        Cuisine.mediterranean => cuisineMediterranean,
      };

  String cuisineDescription(Cuisine cuisine) => switch (cuisine) {
        Cuisine.italian => cuisineItalianDesc,
        Cuisine.asian => cuisineAsianDesc,
        Cuisine.mexican => cuisineMexicanDesc,
        Cuisine.indian => cuisineIndianDesc,
        Cuisine.mediterranean => cuisineMediterraneanDesc,
      };

  String proteinName(RecipeProtein protein) => optionLabel(protein.id);
}

/// Formats an amount with the profile's currency symbol.
String formatMoney(Country country, double amount, {int decimals = 2}) =>
    '${country.currencySymbol}${amount.toStringAsFixed(decimals)}';
