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
      'plan your dinners around your budget,\nyour cravings and what\'s in your kitchen';

  @override
  String get actionContinue => 'continue';

  @override
  String get actionStart => 'get started';

  @override
  String get actionGeneratePlan => 'generate the plan';

  @override
  String get haveACode => 'Have a code?';

  @override
  String get onbLanguageTitle => 'choose your language';

  @override
  String get onbNameTitle => 'what\'s your name?';

  @override
  String get onbNamePlaceholder => 'type here';

  @override
  String get onbAgeTitle => 'how old are you?';

  @override
  String get onbAgeSubtitle =>
      'we only use this to personalise your experience.';

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
  String get onbGoalTitle => 'what do you want to achieve?';

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
  String get onbBlockerTitle => 'what\'s stopping you?';

  @override
  String get blockerNoTime => 'Not enough time';

  @override
  String get blockerTired => 'Too tired after work';

  @override
  String get blockerHard => 'I find cooking hard';

  @override
  String get blockerNoInspiration => 'I\'m out of inspiration';

  @override
  String get onbInfoPlanningTitle => 'meal planning eats your time…';

  @override
  String get onbInfoPlanningSubtitle =>
      'we take that stress away and hand you delicious meals to cook and enjoy';

  @override
  String get onbSavingsTitle =>
      'do you feel you could save more on your groceries?';

  @override
  String get savingsDefinitely => 'Definitely';

  @override
  String get savingsVeryLikely => 'Very likely';

  @override
  String get savingsABit => 'A little';

  @override
  String get savingsNotReally => 'Not really';

  @override
  String get onbCookTimeTitle => 'how long do you usually spend cooking?';

  @override
  String get onbCookTimeSubtitle => 'we\'ll suggest recipes that fit your pace';

  @override
  String get cookTime15to30 => '15–30 min';

  @override
  String get cookTime30to45 => '30–45 min';

  @override
  String get cookTime45to60 => '45–60 min';

  @override
  String get cookTime60plus => '60+ min';

  @override
  String get onbSourceTitle => 'where did you hear about us?';

  @override
  String get sourceInstagram => 'Instagram';

  @override
  String get sourceTikTok => 'TikTok';

  @override
  String get sourceYouTube => 'YouTube';

  @override
  String get sourceFacebook => 'Facebook';

  @override
  String get sourceWordOfMouth => 'Word of mouth';

  @override
  String get sourceAppStore => 'App Store';

  @override
  String get onbInfoBarsTitle => 'plan your week faster';

  @override
  String get onbInfoBarsSubtitle =>
      'less time picking recipes, digging through cupboards and wandering the aisles';

  @override
  String get onbInfoBarsWithUs => 'with us';

  @override
  String get onbInfoBarsWithoutUs => 'without us';

  @override
  String get onbInfoBarsWithUsValue => '5 min';

  @override
  String get onbInfoBarsWithoutUsValue => '60 min';

  @override
  String get onbInfoBarsFooter => 'save almost an hour\nevery week';

  @override
  String get onbCountryTitle => 'where are you from?';

  @override
  String get onbCountrySubtitle =>
      'we use this once — for currency, cuisine and a few local touches';

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
  String get onbEuropeTitle => 'where in Europe are you?';

  @override
  String get onbEuropeSubtitle =>
      'we\'ll set up stores, currency and local touches';

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
  String get onbStoreTitle => 'choose your store';

  @override
  String get onbStoreSubtitle => 'we\'ll plan your weekly shop around it';

  @override
  String get onbHouseholdTitle => 'how many are you cooking for?';

  @override
  String get onbHouseholdSubtitle => 'we\'ll adapt your plan and your budget';

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
  String get onbDaysTitle => 'which days do you cook?';

  @override
  String get onbDaysSubtitle => 'pick the days with planned meals';

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
  String get onbBudgetTitle => 'what\'s your weekly budget?';

  @override
  String get onbBudgetSubtitle => 'choose what you want to spend on those days';

  @override
  String get thisWeek => 'this week';

  @override
  String get onbInfoMoneyTitle => 'you could save\non average';

  @override
  String get onbInfoMoneySubtitle => 'on your groceries every week';

  @override
  String onbInfoMoneyFooter(String amount) {
    return 'that\'s $amount a year!';
  }

  @override
  String get onbCravingsTitle => 'what are you craving?';

  @override
  String get chooseUpToThree => 'choose up to 3';

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
  String get onbDietTitle => 'any dietary requirements?';

  @override
  String get chooseAllThatApply => 'choose all that apply';

  @override
  String get optionNone => 'None';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get onbAllergiesTitle => 'any allergies?';

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
  String get onbProteinsTitle => 'what do you like?';

  @override
  String get onbProteinsHint => 'choose the proteins you enjoy';

  @override
  String get proteinBeef => 'Beef';

  @override
  String get proteinPork => 'Pork';

  @override
  String get proteinChicken => 'Chicken';

  @override
  String get proteinFish => 'Fish';

  @override
  String get onbAppliancesTitle => 'what appliances do you have?';

  @override
  String get onbAppliancesHint => 'choose at least one to plan';

  @override
  String get applianceMicrowave => 'Microwave';

  @override
  String get applianceHob => 'Hob';

  @override
  String get applianceOven => 'Oven';

  @override
  String get applianceAirFryer => 'Air fryer';

  @override
  String get onbTestimonialTitle => 'loved by everyday cooks';

  @override
  String get onbTestimonialSubtitle => 'real people, real progress every week';

  @override
  String get reviewOneName => 'Nicolas';

  @override
  String get reviewOneTitle => 'Feeding three on a small budget';

  @override
  String get reviewOneBody =>
      'The recipes aren\'t fancy but they\'re filling. We spend less every week.';

  @override
  String get reviewTwoName => 'Léa';

  @override
  String get reviewTwoTitle => 'Fast dinners after work';

  @override
  String get reviewTwoBody =>
      'Most meals take under half an hour. That\'s why I stay.';

  @override
  String get reviewThreeName => 'Thomas';

  @override
  String get reviewThreeTitle => 'Real progress every week';

  @override
  String get reviewThreeBody =>
      'Simple after a few tweaks, no conditions and no surprises.';

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
  String get generatingTaskMatch => 'matching meals to your store and budget';

  @override
  String get generatingTaskOrganise => 'organising this week\'s dinners';

  @override
  String get generatingTaskShopping => 'building your shopping list';

  @override
  String get generatingTapToContinue => 'tap to continue';

  @override
  String get generatingReady => 'your plan is ready';

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
  String get regeneratePlan => 'regenerate the plan';

  @override
  String get exploreEyebrow => 'RECIPES';

  @override
  String get exploreTitle => 'explore';

  @override
  String get exploreSearchPlaceholder => 'Search meals';

  @override
  String get exploreCravings => 'Your cravings';

  @override
  String get exploreSeeLess => 'See less';

  @override
  String get exploreSeeMore => 'See more';

  @override
  String get exploreByCuisine => 'Explore by cuisine';

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
    return 'Cook time: $time   |   Servings: $servings';
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
  String get shoppingAddItems => 'Add groceries';

  @override
  String shoppingNeeded(String amount) {
    return '($amount needed)';
  }

  @override
  String get prefsEyebrow => 'YOUR PLAN';

  @override
  String get prefsTitle => 'preferences';

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
  String get prefsCookingDaysSub => 'Which days do you want planned meals?';

  @override
  String get prefsBudget => 'Weekly budget';

  @override
  String prefsBudgetForDays(int count) {
    return ' for $count days';
  }

  @override
  String get prefsCravings => 'Current cravings';

  @override
  String get prefsChooseUpToThree => 'Choose up to 3';

  @override
  String get prefsDiet => 'Dietary requirements';

  @override
  String get prefsChooseAllThatApply => 'Choose all that apply';

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
  String get prefsAppliancesSub => 'Choose at least one to plan';

  @override
  String get accountEyebrow => 'YOUR ACCOUNT';

  @override
  String get accountTitle => 'account';

  @override
  String get accountSignInApple => 'Sign in with Apple';

  @override
  String get accountSignInSub =>
      'Sign in to save your\npreferences to the cloud.';

  @override
  String get accountFamilyPlan => 'Family plan';

  @override
  String get accountFamilyPlanSub => 'Share access to your account.';

  @override
  String get accountInvite => 'Invite friends and family';

  @override
  String accountGreeting(String name) {
    return 'Hi, $name';
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
  String get accountRateTably => 'Rate Tably';

  @override
  String get accountSuggestFeature => 'Suggest a feature';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountResetSaved => 'Reset saved meals';

  @override
  String get accountResetSavedSub => 'Clear your favourites list';

  @override
  String get accountResetHistory => 'Reset suggestion history';

  @override
  String get accountResetHistorySub =>
      'Fresher suggestions when you regenerate';

  @override
  String get accountSectionAlerts => 'ALERTS';

  @override
  String get accountWeeklyReminder => 'Weekly plan reminder';

  @override
  String get accountWeeklyReminderSub => 'Sunday at 10:00 — plan your week';

  @override
  String get accountSectionHelp => 'HELP';

  @override
  String get accountShareTably => 'Share Tably';

  @override
  String get accountContactUs => 'Contact us';

  @override
  String get accountManageSubscription => 'Manage subscription';

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
  String get tabMenu => 'menu';

  @override
  String get tabRecipes => 'Recipes';

  @override
  String get tabPreferences => 'Preferences';

  @override
  String get tabAccount => 'account';

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
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorLoadPlan => 'Couldn\'t load your plan.';

  @override
  String get errorSavePreferences => 'Couldn\'t save your preferences.';

  @override
  String get errorGeneratePlan => 'Couldn\'t generate your plan.';

  @override
  String get errorSignIn => 'Couldn\'t sign in. Try again.';

  @override
  String get errorShoppingUpdate => 'Couldn\'t update your list.';
}
