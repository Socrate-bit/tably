// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tably';

  @override
  String get tagline =>
      'Plan your meals around your budget,\nyour cravings and what\'s in your kitchen';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionStart => 'Get started →';

  @override
  String get actionGeneratePlan => 'Generate my plan';

  @override
  String get haveACode => 'Have a code?';

  @override
  String get haveACodeApplied => 'Code applied ✓';

  @override
  String get onbLanguageTitle => 'Choose your language';

  @override
  String get onbNameTitle => 'What\'s your name?';

  @override
  String get onbNamePlaceholder => 'type here';

  @override
  String get onbAgeTitle => 'How old are you?';

  @override
  String get onbAgeSubtitle =>
      'We only use this to personalise your experience.';

  @override
  String get ageUnder24 => '24 or under';

  @override
  String get age25to34 => '25-34';

  @override
  String get age35to44 => '35-44';

  @override
  String get age45to54 => '45-54';

  @override
  String get age55plus => '55+';

  @override
  String get onbGoalTitle => 'What would you like?';

  @override
  String get goalMealPrep => 'Meal prep for the week';

  @override
  String get goalSimpleRecipes => 'Find really simple recipes';

  @override
  String get goalTastyRecipes => 'Find really tasty recipes';

  @override
  String get goalFeedMyself => 'Feed myself';

  @override
  String get goalFeedFamily => 'Feed my family';

  @override
  String get onbBlockerTitle => 'What gets in the way most?';

  @override
  String get blockerNoTime => 'Not enough time';

  @override
  String get blockerTired => 'Too tired after work';

  @override
  String get blockerHard => 'I find cooking hard';

  @override
  String get blockerNoInspiration => 'I\'m out of inspiration';

  @override
  String get onbInfoPlanningTitle =>
      'Planning meals takes time and can quickly get expensive…';

  @override
  String get onbCookTimeTitle => 'How long do you usually spend cooking?';

  @override
  String get onbCookTimeSubtitle => 'We\'ll suggest recipes that fit your pace';

  @override
  String get cookTime15to30 => '15–30 min';

  @override
  String get cookTime30to45 => '30–45 min';

  @override
  String get cookTime45to60 => '45–60 min';

  @override
  String get cookTime60plus => '60+ min';

  @override
  String get onbInfoBarsTitle => 'Tably helps you plan your week';

  @override
  String get onbInfoBarsSubtitle =>
      'Less time picking recipes, digging through cupboards and wandering the aisles';

  @override
  String get onbInfoBarsWithUs => 'with us';

  @override
  String get onbInfoBarsWithoutUs => 'without us';

  @override
  String get onbInfoBarsWithUsValue => '5 min';

  @override
  String get onbInfoBarsWithoutUsValue => '60 min';

  @override
  String get onbInfoBarsFooter => 'Save almost an hour\nevery week';

  @override
  String get onbCountryTitle => 'Where are you from?';

  @override
  String get onbCountrySubtitle =>
      'We use this once — for currency, cuisine and a few local touches';

  @override
  String get countryUs => 'United States';

  @override
  String get countryEurope => 'Europe';

  @override
  String get countryUk => 'United Kingdom';

  @override
  String get countryAustralia => 'Australia';

  @override
  String get countryCanada => 'Canada';

  @override
  String get countryNewZealand => 'New Zealand';

  @override
  String get countryBrazil => 'Brazil';

  @override
  String get onbEuropeTitle => 'Where in Europe are you?';

  @override
  String get onbEuropeSubtitle =>
      'We set up stores, currency and local touches';

  @override
  String get countryGermany => 'Germany';

  @override
  String get countryIreland => 'Ireland';

  @override
  String get countrySweden => 'Sweden';

  @override
  String get countryNetherlands => 'Netherlands';

  @override
  String get countryFrance => 'France';

  @override
  String get countrySpain => 'Spain';

  @override
  String get countryRestOfEurope => 'Rest of Europe';

  @override
  String get onbStoreTitle => 'Choose your store';

  @override
  String get onbStoreSubtitle => 'We\'ll plan your weekly shop around it';

  @override
  String get onbHouseholdTitle => 'How many are you cooking for?';

  @override
  String get onbHouseholdSubtitle => 'We adapt your plan and budget';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return '$_temp0';
  }

  @override
  String get onbDaysTitle => 'Which days do you cook?';

  @override
  String get onbDaysSubtitle => 'Pick the days you want meals planned';

  @override
  String daysSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days selected',
      one: '1 day selected',
    );
    return '$_temp0';
  }

  @override
  String get onbBudgetTitle => 'What\'s your usual weekly budget?';

  @override
  String get onbBudgetSubtitle => 'How much do you want to spend this week?';

  @override
  String get thisWeek => 'this week';

  @override
  String get onbInfoMoneySubtitle =>
      'On groceries every week, by optimising your meals and comparing store prices';

  @override
  String onbInfoMoneyFooter(String amount) {
    return 'That\'s $amount a year!';
  }

  @override
  String get onbCravingsTitle => 'What are you craving?';

  @override
  String get chooseUpToThree => 'Choose up to 3';

  @override
  String get cravingQuick => 'Quick meals';

  @override
  String get cravingHighProtein => 'High-protein';

  @override
  String get cravingLowCalorie => 'Low calorie';

  @override
  String get cravingFamilyFavourites => 'Family-favourites';

  @override
  String get cravingHealthyComfort => 'Healthy comfort';

  @override
  String get cravingFakeaway => 'Fakeaway';

  @override
  String get cravingEasyDigestion => 'Easy-digestion';

  @override
  String get cravingIndulgent => 'Indulgent';

  @override
  String get onbDietTitle => 'Any dietary preferences?';

  @override
  String get chooseAllThatApply => 'Choose all that apply';

  @override
  String get optionNone => 'None';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get dietHalal => 'Halal';

  @override
  String get onbAllergiesTitle => 'Any allergies?';

  @override
  String get allergyGlutenFree => 'Gluten-free';

  @override
  String get allergyLactoseFree => 'Lactose-free';

  @override
  String get allergyNutFree => 'Nut-free';

  @override
  String get allergyEggFree => 'Egg-free';

  @override
  String get allergyShellfishFree => 'Shellfish-free';

  @override
  String get allergySesameFree => 'Sesame-free';

  @override
  String get allergySoyFree => 'Soy-free';

  @override
  String get onbProteinsTitle => 'What do you like?';

  @override
  String get onbProteinsHint => 'Choose the proteins you enjoy';

  @override
  String get proteinBeef => 'Beef';

  @override
  String get proteinPork => 'Pork';

  @override
  String get proteinChicken => 'Chicken';

  @override
  String get proteinFish => 'Fish';

  @override
  String get onbAppliancesTitle => 'Which appliances do you have?';

  @override
  String get onbAppliancesHint => 'Choose everything you have';

  @override
  String get applianceMicrowave => 'Microwave';

  @override
  String get applianceHob => 'Hob';

  @override
  String get applianceOven => 'Oven';

  @override
  String get applianceAirFryer => 'Air fryer';

  @override
  String get onbTestimonialTitle => 'Already loved by 500,000 people';

  @override
  String get onbTestimonialSubtitle =>
      'Less mental load, less waste, more great meals';

  @override
  String get reviewOneName => 'Nicolas';

  @override
  String get reviewOneTitle =>
      'The whole family fed, without blowing the budget';

  @override
  String get reviewOneBody =>
      'Hearty dishes the kids actually finish, and a grocery bill that drops every week. I don\'t shop without Tably anymore.';

  @override
  String get reviewTwoName => 'Léa';

  @override
  String get reviewTwoTitle => 'Dinner ready before I\'m hungry';

  @override
  String get reviewTwoBody =>
      'When I get home from work, I already know what to cook. 30 minutes tops, and it\'s delicious. My evenings are finally relaxing.';

  @override
  String get reviewThreeName => 'Thomas';

  @override
  String get reviewThreeTitle => 'No more \"what\'s for dinner?\"';

  @override
  String get reviewThreeBody =>
      'My weekly menu and shopping list are ready in one tap. I don\'t think about it anymore, and I eat better than before.';

  @override
  String get ratingTitle => 'Enjoying Tably?';

  @override
  String get ratingSubtitle => 'Tap a star to rate it on the\nApp Store.';

  @override
  String get ratingNotNow => 'Not Now';

  @override
  String generatingTitle(String name) {
    return '$name, we\'re preparing your week';
  }

  @override
  String get generatingTaskMatch => 'Matching meals to your store and budget';

  @override
  String get generatingTaskOrganise => 'Organising the week\'s dinners';

  @override
  String get generatingTaskShopping => 'Creating your shopping list';

  @override
  String get generatingReady => 'Your plan is ready';

  @override
  String get defaultChefName => 'Chef';

  @override
  String plannedFor(String store) {
    return 'planned for $store';
  }

  @override
  String get estimatedCost => 'EST. COST';

  @override
  String get tapToView => 'TAP TO VIEW';

  @override
  String get shoppingList => 'Shopping list';

  @override
  String shoppingBoughtCount(int done, int total) {
    return '$done/$total bought';
  }

  @override
  String shoppingDoneCount(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get regeneratePlan => 'regenerate plan';

  @override
  String get planOutdatedTitle => 'Your preferences changed';

  @override
  String get planOutdatedBody =>
      'Your meals were picked with your previous preferences. Want new ones?';

  @override
  String get planOutdatedRegenerate => 'Regenerate meals';

  @override
  String get planOutdatedKeep => 'Keep these';

  @override
  String get exploreSearchPlaceholder => 'Search meals';

  @override
  String get exploreRecent => 'Recently viewed';

  @override
  String get addRecipeTitle => 'Add a recipe';

  @override
  String get addRecipeImportSocial => 'Import from social';

  @override
  String get addRecipeImportSocialSub => 'From Instagram, TikTok or Facebook';

  @override
  String get addRecipeScanFridge => 'Scan your fridge';

  @override
  String get addRecipeScanFridgeSub =>
      'We\'ll suggest recipes with what you have';

  @override
  String get addRecipePhoto => 'Import a photo';

  @override
  String get addRecipeText => 'Import text';

  @override
  String get addRecipeLink => 'Import a link';

  @override
  String get addRecipeScratch => 'Write from scratch';

  @override
  String get recipeMacros => 'MACROS · PER SERVING';

  @override
  String get macroKcal => 'kcal';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get recipeNotesLabel => 'RECIPE NOTES';

  @override
  String recipeCookTimeAndServings(String time, int servings) {
    return 'Cooking time: $time  |  Servings: $servings';
  }

  @override
  String get recipeMarkCooked => 'Mark as cooked';

  @override
  String get recipeTabIngredients => 'Ingredients';

  @override
  String get recipeTabPreparation => 'Preparation';

  @override
  String get recipeCookStepByStep => 'Cook step by step';

  @override
  String get recipeYourNotes => 'Your notes';

  @override
  String get recipeNotePlaceholder => 'Add a note to this recipe...';

  @override
  String get recipeAddToWeek => 'Add to this week\'s menu';

  @override
  String get shoppingEyebrow => 'THIS WEEK';

  @override
  String get shoppingCopyList => 'Copy the list';

  @override
  String get shoppingShare => 'Share';

  @override
  String get shoppingUpdating => 'Updating your list…';

  @override
  String get shoppingShareHeader =>
      'Hi there! 👋\n\nHere\'s our shopping list for the week, so we\'ve got everything we need for some tasty meals 🍽️ Happy shopping! 🛒\n\nMade with Tably 💚';

  @override
  String shoppingNeeded(String amount) {
    return '($amount needed)';
  }

  @override
  String get prefsTitle => 'Preferences';

  @override
  String get prefsCountry => 'Country';

  @override
  String get prefsStore => 'Supermarket';

  @override
  String get prefsHousehold => 'Household size';

  @override
  String get prefsHouseholdSub => 'How many are you cooking for?';

  @override
  String get prefsCookingDays => 'Cooking days';

  @override
  String get prefsCookingDaysSub => 'Which days do you want meals planned?';

  @override
  String get prefsBudget => 'Weekly budget';

  @override
  String prefsBudgetForDays(int count) {
    return ' for $count days';
  }

  @override
  String get prefsCravings => 'Current cravings';

  @override
  String get prefsDiet => 'Dietary preferences';

  @override
  String get prefsAllergens => 'Allergens';

  @override
  String get prefsProteins => 'Preferences';

  @override
  String get prefsProteinsSub =>
      'We\'ll steer your plan towards the proteins you choose';

  @override
  String get prefsAppliances => 'Kitchen appliances';

  @override
  String get prefsAppliancesSub => 'Choose everything you have';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSignInApple => 'Sign in with Apple';

  @override
  String get accountSignInSub =>
      'Sign in to save your\npreferences to the cloud.';

  @override
  String accountGreeting(String name) {
    return 'Hi, $name ✎';
  }

  @override
  String accountShoppingAt(String store) {
    return 'Shopping at $store';
  }

  @override
  String get accountActive => 'Active';

  @override
  String get accountSectionApp => 'APP';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountSectionLegal => 'LEGAL';

  @override
  String get accountPrivacy => 'Privacy policy';

  @override
  String get accountTerms => 'Terms of use';

  @override
  String get accountSectionAccount => 'ACCOUNT';

  @override
  String get accountDelete => 'Delete my account';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountEnterReferralCode => 'Enter a referral code';

  @override
  String get accountPlanFree => 'Free';

  @override
  String get accountPlanAdmin => 'Admin';

  @override
  String get accountPlanUgc => 'Creator';

  @override
  String get referralTitle => 'Referral code';

  @override
  String get referralSubtitle => 'Enter your code to unlock access.';

  @override
  String get referralPlaceholder => 'YOUR CODE';

  @override
  String get referralSubmit => 'Redeem';

  @override
  String get referralCancel => 'Cancel';

  @override
  String get referralInvalid => 'Invalid code';

  @override
  String get referralLimit => 'This code has reached its usage limit';

  @override
  String get referralAlreadyUsed => 'You have already used this code';

  @override
  String get referralError => 'Something went wrong, please try again';

  @override
  String get tabMenu => 'Week';

  @override
  String get tabRecipes => 'Recipes';

  @override
  String get tabPreferences => 'Preferences';

  @override
  String get tabAccount => 'Account';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get dayShortMonday => 'M';

  @override
  String get dayShortTuesday => 'T';

  @override
  String get dayShortWednesday => 'W';

  @override
  String get dayShortThursday => 'T';

  @override
  String get dayShortFriday => 'F';

  @override
  String get dayShortSaturday => 'S';

  @override
  String get dayShortSunday => 'S';

  @override
  String get errorSavePreferences => 'Couldn\'t save your preferences.';

  @override
  String get errorGeneratePlan => 'Couldn\'t generate your plan.';

  @override
  String get errorSignIn => 'Couldn\'t sign in. Try again.';

  @override
  String get errorOpenLink => 'Couldn\'t open the link.';

  @override
  String get errorShoppingUpdate => 'Couldn\'t update your list.';

  @override
  String get errorShoppingShare => 'Couldn\'t share your list.';

  @override
  String get blockerSaving => 'I\'m trying to save money';

  @override
  String get onbInfoMoneyEyebrow => 'WITH TABLY, PEOPLE SAVE ON AVERAGE';

  @override
  String get onbInfoMoneyPerWeek => 'per week';

  @override
  String get onbPlanStartTitle => 'Let\'s build your week';

  @override
  String get onbPlanStartSubtitle =>
      'A few questions about your kitchen and budget, and your plan is ready.';

  @override
  String get onbMealsTitle => 'How many meals a day?';

  @override
  String get onbMealsSubtitle => 'We’ll plan around your routine';

  @override
  String mealsPerDayOption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals a day',
      one: '1 meal a day',
    );
    return '$_temp0';
  }

  @override
  String get mealsPerDayDinnerOnly => 'Dinner only';

  @override
  String get mealsPerDayLunchDinner => 'Lunch + dinner';

  @override
  String get onbDiversityTitle => 'How much variety?';

  @override
  String get onbDiversitySubtitle =>
      'Some dishes come back as leftovers so you don’t cook every day';

  @override
  String get diversityAllDifferent => 'Freshly cooked at every meal';

  @override
  String get varietyHigh => 'Maximum variety';

  @override
  String get varietyBalanced => 'Balanced';

  @override
  String get varietyLow => 'Batch cooking';

  @override
  String diversityDetailReuse(int recipes, int slots) {
    return 'Only $recipes recipes to cook for $slots meals';
  }

  @override
  String get slotLunch => 'Lunch';

  @override
  String get slotDinner => 'Dinner';

  @override
  String get switchEyebrow => 'GOOD NEWS';

  @override
  String get switchTitlePrefix => 'Your recipes would cost ';

  @override
  String switchTitleHighlight(int percent) {
    return '$percent% less';
  }

  @override
  String switchTitleSuffix(String store) {
    return ' at $store';
  }

  @override
  String switchSubtitle(String store) {
    return 'Based on your profile and this week’s basket. You can switch now or keep $store.';
  }

  @override
  String switchAccept(String store) {
    return 'Switch to $store';
  }

  @override
  String switchDecline(String store) {
    return 'Keep $store';
  }

  @override
  String budgetSavings(String amount) {
    return '$amount saved 🎉';
  }

  @override
  String planCounts(int slots, int recipes) {
    return '$slots meals · $recipes recipes to cook';
  }

  @override
  String get leftoverBadge => '♻ Leftover';

  @override
  String get regeneratingPlan => 'new plan on its way…';

  @override
  String get storesTitle => 'Supermarket';

  @override
  String get storesSubtitle => 'French estimate, may vary by store and region';

  @override
  String get storesCurrent => 'Your current store';

  @override
  String storesCheaper(String amount, String store) {
    return '$amount less than $store';
  }

  @override
  String storesPricier(String amount) {
    return '$amount more';
  }

  @override
  String get storesCurrentTag => 'CURRENT';

  @override
  String get recipesTitle => 'Recipes';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String searchEmpty(String query) {
    return 'No meals match “$query”.\nTry an ingredient or a type of dish.';
  }

  @override
  String get recipesAll => 'Recipes';

  @override
  String get filtersEmpty => 'No recipes match these filters.';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersReset => 'Reset';

  @override
  String get filtersResetAll => 'Reset filters';

  @override
  String get filtersCravings => 'Your cravings';

  @override
  String get filtersCuisine => 'Cuisine';

  @override
  String get filtersProtein => 'Preference';

  @override
  String get filtersProteinSub => 'The meat or protein you want to see';

  @override
  String get filtersPrice => 'Price per portion';

  @override
  String filtersPriceRange(String min, String max) {
    return '$min – $max';
  }

  @override
  String get filtersPriceAll => 'All recipes';

  @override
  String filtersPriceUpTo(String amount) {
    return 'Recipes up to $amount per portion';
  }

  @override
  String get filtersApply => 'Show recipes';

  @override
  String get proteinTofu => 'Tofu';

  @override
  String get cuisineItalian => 'Italian';

  @override
  String get cuisineItalianDesc => 'Pasta • Risotto • Gnocchi';

  @override
  String get cuisineAsian => 'Asian';

  @override
  String get cuisineAsianDesc => 'Noodles • Curry • Stir-fry';

  @override
  String get cuisineMexican => 'Mexican';

  @override
  String get cuisineMexicanDesc => 'Tacos • Burritos • Fajitas';

  @override
  String get cuisineIndian => 'Indian';

  @override
  String get cuisineIndianDesc => 'Curry • Tikka • Tandoori';

  @override
  String get cuisineMediterranean => 'Mediterranean';

  @override
  String get cuisineMediterraneanDesc => 'Gyros • Halloumi • Falafel';

  @override
  String get favouritesTitle => 'Favourites';

  @override
  String favouritesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved recipes',
      one: '1 saved recipe',
    );
    return '$_temp0';
  }

  @override
  String get favouritesEmpty =>
      'No favourites yet.\nTap the heart on a recipe to save it.';

  @override
  String get replaceTitle => 'Replace with';

  @override
  String replaceSubtitleSlot(String day) {
    return 'Choose the dish that replaces $day’s';
  }

  @override
  String get replaceSubtitleWeek => 'Choose the dish it replaces in your week';

  @override
  String get replaceAll => 'All';

  @override
  String get replaceFavourites => 'Favourites';

  @override
  String get replaceEmptyFavourites => 'No favourites yet.';

  @override
  String get replaceEmptySearch => 'No meals match this search.';

  @override
  String get recipeCreatedBy => 'RECIPE BY';

  @override
  String get recipeReplaceMeal => 'Choose another meal';

  @override
  String get recipeRegenerateMeal => 'Regenerate';

  @override
  String get prefsMealsPerDay => 'Meals per day';

  @override
  String get prefsMealsPerDaySub =>
      'Dishes are reused as leftovers to keep the number of recipes down';

  @override
  String get prefsVariety => 'Variety';

  @override
  String get mockCostShort => 'EST. COST';

  @override
  String get mockTapShort => 'TAP';

  @override
  String get mockMealCajun => 'Cajun chicken rice';

  @override
  String get mockMealSatay => 'Tofu satay noodles';

  @override
  String get mockMealSweetChilli => 'Sweet chilli chicken rice boxes';

  @override
  String get aisleProduce => 'FRUIT & VEG';

  @override
  String get aisleMeatFish => 'MEAT & FISH';

  @override
  String get aislePastaRice => 'PASTA, RICE & NOODLES';

  @override
  String get aisleTinsSauces => 'TINS, JARS & SAUCES';

  @override
  String get aisleHerbsGrocery => 'HERBS, SPICES & PANTRY';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'l';

  @override
  String get unitTbsp => 'tbsp';

  @override
  String get unitTsp => 'tsp';

  @override
  String unitClove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cloves',
      one: 'clove',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'slices',
      one: 'slice',
    );
    return '$_temp0';
  }

  @override
  String unitBunch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bunches',
      one: 'bunch',
    );
    return '$_temp0';
  }

  @override
  String unitSprig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sprigs',
      one: 'sprig',
    );
    return '$_temp0';
  }

  @override
  String unitLeaf(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'leaves',
      one: 'leaf',
    );
    return '$_temp0';
  }

  @override
  String unitPinch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pinches',
      one: 'pinch',
    );
    return '$_temp0';
  }

  @override
  String unitCan(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cans',
      one: 'can',
    );
    return '$_temp0';
  }

  @override
  String unitPack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'packs',
      one: 'pack',
    );
    return '$_temp0';
  }

  @override
  String get unitToTaste => 'to taste';

  @override
  String get actionRetry => 'Try again';

  @override
  String get generatingFailed => 'We couldn\'t prepare your recipes right now.';

  @override
  String get catalogueBuilding => 'Preparing your recipes…';

  @override
  String get errorCatalogue => 'Couldn\'t load your recipes.';

  @override
  String get errorCatalogueQuota =>
      'Today\'s recipe search limit has been reached.';

  @override
  String get errorCatalogueEmpty => 'No recipes match your preferences.';

  @override
  String get searchReload => 'Search again';

  @override
  String get searchLoading => 'Searching for recipes…';

  @override
  String searchPrompt(String query) {
    return 'Search for “$query”';
  }

  @override
  String get filtersFromPreferences =>
      'Your preferences by default, adjustable for this search';

  @override
  String get proteinNoMeat => 'No meat';

  @override
  String get applianceMixer => 'Blender';

  @override
  String get applianceSlowCooker => 'Slow cooker';

  @override
  String get appliancePressureCooker => 'Pressure cooker';

  @override
  String get applianceBarbecue => 'Barbecue';

  @override
  String get cookTimeTitle => 'Cooking time';

  @override
  String get cookTimeSub => 'The longest a recipe may take';

  @override
  String cookTimeMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get cookTimeNoLimit => 'No limit';

  @override
  String get prefsCustomInstructions => 'Custom instructions';

  @override
  String get prefsCustomInstructionsSub =>
      'Tably follows them when picking your recipes';

  @override
  String get prefsCustomInstructionsHint =>
      'E.g. no mushrooms, not too spicy, no raw fish…';
}
