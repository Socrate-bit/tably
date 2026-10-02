// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Tably';

  @override
  String get tagline =>
      'Planifie tes repas selon ton budget,\ntes envies et ce qu\'il y a dans ta cuisine';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionStart => 'Commencer →';

  @override
  String get actionGeneratePlan => 'Générer le plan';

  @override
  String get haveACode => 'Tu as un code ?';

  @override
  String get haveACodeApplied => 'Code appliqué ✓';

  @override
  String get onbLanguageTitle => 'Choose your language';

  @override
  String get onbNameTitle => 'Comment tu t\'appelles ?';

  @override
  String get onbNamePlaceholder => 'saisis ici';

  @override
  String get onbAgeTitle => 'Quel âge as-tu ?';

  @override
  String get onbAgeSubtitle =>
      'Nous n\'utilisons ces informations que pour personnaliser ton expérience.';

  @override
  String get ageUnder24 => '24 ans ou moins';

  @override
  String get age25to34 => '25-34';

  @override
  String get age35to44 => '35-44';

  @override
  String get age45to54 => '45-54';

  @override
  String get age55plus => '55+';

  @override
  String get onbGoalTitle => 'Qu\'est-ce que tu aimerais ?';

  @override
  String get goalMealPrep => 'Meal prep pour la semaine';

  @override
  String get goalSimpleRecipes => 'Trouver des recettes super simples';

  @override
  String get goalTastyRecipes => 'Trouver des recettes super gourmandes';

  @override
  String get goalFeedMyself => 'Me nourrir';

  @override
  String get goalFeedFamily => 'Nourrir ma famille';

  @override
  String get onbBlockerTitle => 'Quels sont les plus gros obstacles ?';

  @override
  String get blockerNoTime => 'Manque de temps';

  @override
  String get blockerTired => 'Trop fatigué(e) après le travail';

  @override
  String get blockerHard => 'Je trouve la cuisine difficile';

  @override
  String get blockerNoInspiration => 'Je manque d\'inspiration';

  @override
  String get onbInfoPlanningTitle =>
      'Planifier les repas, c\'est chronophage et ça peut vite coûter cher…';

  @override
  String get onbCookTimeTitle =>
      'Combien de temps mets-tu en général à cuisiner ?';

  @override
  String get onbCookTimeSubtitle =>
      'On te proposera des recettes adaptées à ton rythme';

  @override
  String get cookTime15to30 => '15–30 min';

  @override
  String get cookTime30to45 => '30–45 min';

  @override
  String get cookTime45to60 => '45–60 min';

  @override
  String get cookTime60plus => '60+ min';

  @override
  String get onbInfoBarsTitle => 'Tably t\'aide à planifier ta semaine';

  @override
  String get onbInfoBarsSubtitle =>
      'Moins de temps à choisir des recettes, fouiller le placard et traîner en rayon';

  @override
  String get onbInfoBarsWithUs => 'avec nous';

  @override
  String get onbInfoBarsWithoutUs => 'sans nous';

  @override
  String get onbInfoBarsWithUsValue => '5 min';

  @override
  String get onbInfoBarsWithoutUsValue => '60 min';

  @override
  String get onbInfoBarsFooter => 'Gagne presque une heure\nchaque semaine';

  @override
  String get onbCountryTitle => 'D\'où viens-tu ?';

  @override
  String get onbCountrySubtitle =>
      'On s\'en sert une fois — pour la devise, la cuisine et quelques touches locales';

  @override
  String get countryUs => 'États-Unis';

  @override
  String get countryEurope => 'Europe';

  @override
  String get countryUk => 'Royaume-Uni';

  @override
  String get countryAustralia => 'Australie';

  @override
  String get countryCanada => 'Canada';

  @override
  String get countryNewZealand => 'Nouvelle-Zélande';

  @override
  String get countryBrazil => 'Brésil';

  @override
  String get onbEuropeTitle => 'Où es-tu en Europe ?';

  @override
  String get onbEuropeSubtitle =>
      'On configure les magasins, la devise et les touches locales';

  @override
  String get countryGermany => 'Allemagne';

  @override
  String get countryIreland => 'Irlande';

  @override
  String get countrySweden => 'Suède';

  @override
  String get countryNetherlands => 'Pays-Bas';

  @override
  String get countryFrance => 'France';

  @override
  String get countrySpain => 'Espagne';

  @override
  String get countryRestOfEurope => 'Reste de l\'Europe';

  @override
  String get onbStoreTitle => 'Choisis ton magasin';

  @override
  String get onbStoreSubtitle => 'On planifie tes courses de la semaine autour';

  @override
  String get onbHouseholdTitle => 'Pour combien tu cuisines ?';

  @override
  String get onbHouseholdSubtitle => 'On adapte ton plan et ton budget';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personnes',
      one: 'personne',
    );
    return '$_temp0';
  }

  @override
  String get onbDaysTitle => 'Quels jours tu cuisines ?';

  @override
  String get onbDaysSubtitle => 'Choisis les jours avec des repas planifiés';

  @override
  String daysSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours sélectionnés',
      one: '1 jour sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get onbBudgetTitle => 'Quel est ton budget hebdo habituel ?';

  @override
  String get onbBudgetSubtitle => 'Combien tu veux dépenser cette semaine ?';

  @override
  String get thisWeek => 'cette semaine';

  @override
  String get onbInfoMoneySubtitle =>
      'Sur les courses chaque semaine, en optimisant tes repas et comparant les prix en magasin';

  @override
  String onbInfoMoneyFooter(String amount) {
    return 'Soit $amount par an !';
  }

  @override
  String get onbCravingsTitle => 'Tu as envie de quoi ?';

  @override
  String get chooseUpToThree => 'Choisis jusqu\'à 3';

  @override
  String get cravingQuick => 'Repas express';

  @override
  String get cravingHighProtein => 'Riche en-protéines';

  @override
  String get cravingLowCalorie => 'Peu calorique';

  @override
  String get cravingFamilyFavourites => 'Favoris-familiaux';

  @override
  String get cravingHealthyComfort => 'Comfort sain';

  @override
  String get cravingFakeaway => 'Fakeaway';

  @override
  String get cravingEasyDigestion => 'Digestion-facile';

  @override
  String get cravingIndulgent => 'Gourmand';

  @override
  String get onbDietTitle => 'Des régimes alimentaires ?';

  @override
  String get chooseAllThatApply =>
      'Choisis toutes les options qui s\'appliquent';

  @override
  String get optionNone => 'Aucun';

  @override
  String get dietVegetarian => 'Végétarien';

  @override
  String get dietVegan => 'Végan';

  @override
  String get dietPescatarian => 'Pescétarien';

  @override
  String get dietHalal => 'Halal';

  @override
  String get onbAllergiesTitle => 'Des allergies ?';

  @override
  String get allergyGlutenFree => 'Sans gluten';

  @override
  String get allergyLactoseFree => 'Sans lactose';

  @override
  String get allergyNutFree => 'Sans fruits à coque';

  @override
  String get allergyEggFree => 'Sans œuf';

  @override
  String get allergyShellfishFree => 'Sans crustacés';

  @override
  String get allergySesameFree => 'Sans sésame';

  @override
  String get allergySoyFree => 'Sans soja';

  @override
  String get onbProteinsTitle => 'Qu\'est-ce que tu aimes ?';

  @override
  String get onbProteinsHint => 'Choisis les protéines que tu apprécies';

  @override
  String get proteinBeef => 'Bœuf';

  @override
  String get proteinPork => 'Porc';

  @override
  String get proteinChicken => 'Poulet';

  @override
  String get proteinFish => 'Poisson';

  @override
  String get onbAppliancesTitle => 'Quels appareils tu as ?';

  @override
  String get onbAppliancesHint => 'Choisis au moins un pour planifier';

  @override
  String get applianceMicrowave => 'Micro-ondes';

  @override
  String get applianceHob => 'Plaques';

  @override
  String get applianceOven => 'Four';

  @override
  String get applianceAirFryer => 'Friteuse à air chaud';

  @override
  String get onbTestimonialTitle =>
      'Déjà 500 000 personnes ne s\'en passent plus';

  @override
  String get onbTestimonialSubtitle =>
      'Moins de charge mentale, moins de gaspillage, plus de bons repas';

  @override
  String get reviewOneName => 'Nicolas';

  @override
  String get reviewOneTitle =>
      'Toute la famille à table, sans exploser le budget';

  @override
  String get reviewOneBody =>
      'Des plats généreux que les enfants finissent, et un ticket de caisse qui baisse chaque semaine. Je ne fais plus mes courses sans Tably.';

  @override
  String get reviewTwoName => 'Léa';

  @override
  String get reviewTwoTitle => 'Le dîner prêt avant d\'avoir faim';

  @override
  String get reviewTwoBody =>
      'En rentrant du boulot, je sais déjà quoi cuisiner. 30 minutes max, et c\'est délicieux. Mes soirées sont enfin reposantes.';

  @override
  String get reviewThreeName => 'Thomas';

  @override
  String get reviewThreeTitle => 'Fini le « on mange quoi ce soir ? »';

  @override
  String get reviewThreeBody =>
      'Mon menu de la semaine et ma liste de courses sont prêts en un clic. Je n\'y pense plus, et je mange mieux qu\'avant.';

  @override
  String get ratingTitle => 'Enjoying Tably?';

  @override
  String get ratingSubtitle => 'Tap a star to rate it on the\nApp Store.';

  @override
  String get ratingNotNow => 'Not Now';

  @override
  String generatingTitle(String name) {
    return '$name, on prépare ta semaine';
  }

  @override
  String get generatingTaskMatch =>
      'Accord des repas avec ton magasin et ton budget';

  @override
  String get generatingTaskOrganise => 'Organisation des dîners de la semaine';

  @override
  String get generatingTaskShopping => 'Création de ta liste de courses';

  @override
  String get generatingReady => 'Ton plan est prêt';

  @override
  String get defaultChefName => 'Chef';

  @override
  String plannedFor(String store) {
    return 'prévu pour $store';
  }

  @override
  String get estimatedCost => 'COÛT EST.';

  @override
  String get tapToView => 'APPUYER POUR VOIR';

  @override
  String get shoppingList => 'Liste de courses';

  @override
  String shoppingBoughtCount(int done, int total) {
    return '$done/$total achetés';
  }

  @override
  String shoppingDoneCount(int done, int total) {
    return '$done/$total faits';
  }

  @override
  String get regeneratePlan => 'régénérer le plan';

  @override
  String get exploreSearchPlaceholder => 'Rechercher des repas';

  @override
  String get exploreRecent => 'Consultés récemment';

  @override
  String get addRecipeTitle => 'Ajouter une recette';

  @override
  String get addRecipeImportSocial => 'Importer des réseaux';

  @override
  String get addRecipeImportSocialSub => 'Depuis Instagram, TikTok ou Facebook';

  @override
  String get addRecipeScanFridge => 'Scanner ton frigo';

  @override
  String get addRecipeScanFridgeSub =>
      'On propose des recettes avec ce que tu as';

  @override
  String get addRecipePhoto => 'Importer une photo';

  @override
  String get addRecipeText => 'Importer du texte';

  @override
  String get addRecipeLink => 'Importer un lien';

  @override
  String get addRecipeScratch => 'Écrire de zéro';

  @override
  String get recipeMacros => 'MACROS · PAR PORTION';

  @override
  String get macroKcal => 'kcal';

  @override
  String get macroProtein => 'Protéines';

  @override
  String get macroCarbs => 'Glucides';

  @override
  String get macroFat => 'Lipides';

  @override
  String get recipeNotesLabel => 'NOTES DE RECETTE';

  @override
  String recipeCookTimeAndServings(String time, int servings) {
    return 'Temps de cuisson: $time  |  Portions: $servings';
  }

  @override
  String get recipeMarkCooked => 'Marquer comme cuisiné';

  @override
  String get recipeTabIngredients => 'Ingrédients';

  @override
  String get recipeTabPreparation => 'Préparation';

  @override
  String get recipeCookStepByStep => 'Cuisiner étape par étape';

  @override
  String get recipeYourNotes => 'Tes notes';

  @override
  String get recipeNotePlaceholder => 'Ajoute une note à cette recette...';

  @override
  String get recipeAddToWeek => 'Ajouter au menu de la semaine';

  @override
  String get shoppingEyebrow => 'CETTE SEMAINE';

  @override
  String get shoppingCopyList => 'Copier la liste';

  @override
  String get shoppingShare => 'Partager';

  @override
  String shoppingNeeded(String amount) {
    return '($amount nécessaire)';
  }

  @override
  String get prefsTitle => 'Préférences';

  @override
  String get prefsCountry => 'Pays';

  @override
  String get prefsStore => 'Supermarché';

  @override
  String get prefsHousehold => 'Taille du foyer';

  @override
  String get prefsHouseholdSub => 'Pour combien tu cuisines ?';

  @override
  String get prefsCookingDays => 'Jours de cuisine';

  @override
  String get prefsCookingDaysSub => 'Quels jours veux-tu des repas planifiés ?';

  @override
  String get prefsBudget => 'Budget hebdomadaire';

  @override
  String prefsBudgetForDays(int count) {
    return ' pour $count jours';
  }

  @override
  String get prefsCravings => 'Envie du moment';

  @override
  String get prefsDiet => 'Régimes alimentaires';

  @override
  String get prefsAllergens => 'Allergènes';

  @override
  String get prefsProteins => 'Préférences';

  @override
  String get prefsProteinsSub =>
      'On orientera ton plan vers les protéines que tu choisis';

  @override
  String get prefsAppliances => 'Appareils de cuisine';

  @override
  String get prefsAppliancesSub => 'Choisis au moins un pour planifier';

  @override
  String get accountTitle => 'Compte';

  @override
  String get accountSignInApple => 'Se connecter avec Apple';

  @override
  String get accountSignInSub =>
      'Connecte-toi pour enregistrer tes\npréférences dans le cloud.';

  @override
  String accountGreeting(String name) {
    return 'Salut, $name ✎';
  }

  @override
  String accountShoppingAt(String store) {
    return 'Courses chez $store';
  }

  @override
  String get accountActive => 'Actif';

  @override
  String get accountSectionApp => 'APP';

  @override
  String get accountLanguage => 'Langue';

  @override
  String get accountSectionLegal => 'MENTIONS LÉGALES';

  @override
  String get accountPrivacy => 'Politique de confidentialité';

  @override
  String get accountTerms => 'Conditions d\'utilisation';

  @override
  String get accountSectionAccount => 'COMPTE';

  @override
  String get accountDelete => 'Supprimer mon compte';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountEnterReferralCode => 'Saisir un code de parrainage';

  @override
  String get accountPlanFree => 'Gratuit';

  @override
  String get accountPlanAdmin => 'Admin';

  @override
  String get accountPlanUgc => 'Créateur';

  @override
  String get referralTitle => 'Code de parrainage';

  @override
  String get referralSubtitle => 'Saisis ton code pour débloquer l\'accès.';

  @override
  String get referralPlaceholder => 'TON CODE';

  @override
  String get referralSubmit => 'Valider';

  @override
  String get referralCancel => 'Annuler';

  @override
  String get referralInvalid => 'Code invalide';

  @override
  String get referralLimit => 'Ce code a atteint sa limite d\'utilisation';

  @override
  String get referralAlreadyUsed => 'Tu as déjà utilisé ce code';

  @override
  String get referralError => 'Une erreur est survenue, réessaie';

  @override
  String get tabMenu => 'Semaine';

  @override
  String get tabRecipes => 'Recettes';

  @override
  String get tabPreferences => 'Préférence';

  @override
  String get tabAccount => 'Compte';

  @override
  String get dayMonday => 'Lundi';

  @override
  String get dayTuesday => 'Mardi';

  @override
  String get dayWednesday => 'Mercredi';

  @override
  String get dayThursday => 'Jeudi';

  @override
  String get dayFriday => 'Vendredi';

  @override
  String get daySaturday => 'Samedi';

  @override
  String get daySunday => 'Dimanche';

  @override
  String get dayShortMonday => 'L';

  @override
  String get dayShortTuesday => 'M';

  @override
  String get dayShortWednesday => 'M';

  @override
  String get dayShortThursday => 'J';

  @override
  String get dayShortFriday => 'V';

  @override
  String get dayShortSaturday => 'S';

  @override
  String get dayShortSunday => 'D';

  @override
  String get errorSavePreferences =>
      'Impossible d\'enregistrer tes préférences.';

  @override
  String get errorGeneratePlan => 'Impossible de générer ton plan.';

  @override
  String get errorSignIn => 'Connexion impossible. Réessaie.';

  @override
  String get errorOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get errorShoppingUpdate => 'Impossible de mettre à jour ta liste.';

  @override
  String get errorShoppingShare => 'Impossible de partager ta liste.';

  @override
  String get blockerSaving => 'J\'essaye de faire des économies';

  @override
  String get onbInfoMoneyEyebrow => 'AVEC TABLY, ON ÉCONOMISE EN MOYENNE';

  @override
  String get onbInfoMoneyPerWeek => 'par semaine';

  @override
  String get onbPlanStartTitle => 'On attaque ton plan de la semaine';

  @override
  String get onbPlanStartSubtitle =>
      'Quelques questions sur ta cuisine et ton budget, et ton plan est prêt.';

  @override
  String get onbMealsTitle => 'Combien de repas par jour ?';

  @override
  String get onbMealsSubtitle => 'On adapte ton plan à ton rythme';

  @override
  String mealsPerDayOption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repas par jour',
      one: '1 repas par jour',
    );
    return '$_temp0';
  }

  @override
  String get mealsPerDayDinnerOnly => 'Dîner seulement';

  @override
  String get mealsPerDayLunchDinner => 'Déjeuner + dîner';

  @override
  String get onbDiversityTitle => 'Combien de variété ?';

  @override
  String get onbDiversitySubtitle =>
      'On réutilise certains plats en restes pour t\'éviter de cuisiner tous les jours';

  @override
  String get diversityAllDifferent => 'On cuisine à chaque repas';

  @override
  String get varietyHigh => 'Un max de variété';

  @override
  String get varietyBalanced => 'Équilibré';

  @override
  String get varietyLow => 'Batch cooking';

  @override
  String diversityDetailReuse(int recipes, int slots) {
    return 'Seulement $recipes recettes à cuisiner pour $slots repas';
  }

  @override
  String get slotLunch => 'Déjeuner';

  @override
  String get slotDinner => 'Dîner';

  @override
  String get switchEyebrow => 'BONNE NOUVELLE';

  @override
  String get switchTitlePrefix => 'Tes recettes coûteraient ';

  @override
  String switchTitleHighlight(int percent) {
    return '$percent % moins cher';
  }

  @override
  String switchTitleSuffix(String store) {
    return ' chez $store';
  }

  @override
  String switchSubtitle(String store) {
    return 'D\'après ton profil et ton panier de la semaine. Tu peux changer maintenant ou garder $store.';
  }

  @override
  String switchAccept(String store) {
    return 'Passer à $store';
  }

  @override
  String switchDecline(String store) {
    return 'Garder $store';
  }

  @override
  String budgetSavings(String amount) {
    return '$amount d\'économie 🎉';
  }

  @override
  String planCounts(int slots, int recipes) {
    return '$slots repas · $recipes recettes à cuisiner';
  }

  @override
  String get leftoverBadge => '♻ Reste';

  @override
  String get regeneratingPlan => 'nouveau plan en cours…';

  @override
  String get storesTitle => 'Supermarché';

  @override
  String get storesSubtitle =>
      'Estimation France, peut varier selon le magasin et la région';

  @override
  String get storesCurrent => 'Ton magasin actuel';

  @override
  String storesCheaper(String amount, String store) {
    return '$amount de moins que $store';
  }

  @override
  String storesPricier(String amount) {
    return '$amount de plus';
  }

  @override
  String get storesCurrentTag => 'ACTUEL';

  @override
  String get recipesTitle => 'Recettes';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String searchEmpty(String query) {
    return 'Aucun repas ne correspond à « $query ».\nEssaie un ingrédient ou un type de plat.';
  }

  @override
  String get recipesAll => 'Recettes';

  @override
  String get filtersEmpty => 'Aucune recette ne correspond à ces filtres.';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filtersReset => 'Réinitialiser';

  @override
  String get filtersCravings => 'Tes envies';

  @override
  String get filtersCuisine => 'Cuisine type';

  @override
  String get filtersProtein => 'Préférence';

  @override
  String get filtersProteinSub =>
      'Le type de viande ou de protéine que tu veux voir';

  @override
  String get filtersPrice => 'Prix par portion';

  @override
  String filtersPriceRange(String min, String max) {
    return '$min – $max';
  }

  @override
  String get filtersPriceAll => 'Toutes les recettes';

  @override
  String filtersPriceUpTo(String amount) {
    return 'Recettes jusqu\'à $amount par portion';
  }

  @override
  String get filtersApply => 'Voir les recettes';

  @override
  String get proteinTofu => 'Tofu';

  @override
  String get cuisineItalian => 'Italienne';

  @override
  String get cuisineItalianDesc => 'Pasta • Risotto • Gnocchi';

  @override
  String get cuisineAsian => 'Asiatique';

  @override
  String get cuisineAsianDesc => 'Nouilles • Curry • Sauté';

  @override
  String get cuisineMexican => 'Mexicaine';

  @override
  String get cuisineMexicanDesc => 'Tacos • Burritos • Fajitas';

  @override
  String get cuisineIndian => 'Indienne';

  @override
  String get cuisineIndianDesc => 'Curry • Tikka • Tandoori';

  @override
  String get cuisineMediterranean => 'Méditerranéenne';

  @override
  String get cuisineMediterraneanDesc => 'Gyros • Halloumi • Falafel';

  @override
  String get favouritesTitle => 'Favoris';

  @override
  String favouritesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recettes enregistrées',
      one: '1 recette enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get favouritesEmpty =>
      'Aucun favori pour l\'instant.\nAppuie sur le cœur d\'une recette pour l\'enregistrer.';

  @override
  String get replaceTitle => 'Remplacer par';

  @override
  String replaceSubtitleSlot(String day) {
    return 'Choisis le plat qui remplace celui de $day';
  }

  @override
  String get replaceSubtitleWeek =>
      'Choisis le plat qui prend sa place dans la semaine';

  @override
  String get replaceAll => 'Toutes';

  @override
  String get replaceFavourites => 'Favoris';

  @override
  String get replaceEmptyFavourites => 'Aucun favori pour l\'instant.';

  @override
  String get replaceEmptySearch =>
      'Aucun repas ne correspond à cette recherche.';

  @override
  String get recipeCreatedBy => 'RECETTE DE';

  @override
  String get recipeReplaceMeal => 'Choisir un autre repas';

  @override
  String get recipeRegenerateMeal => 'Régénérer';

  @override
  String get prefsMealsPerDay => 'Repas par jour';

  @override
  String get prefsMealsPerDaySub =>
      'Les plats sont réutilisés en restes pour limiter le nombre de recettes';

  @override
  String get prefsVariety => 'Variété';

  @override
  String get mockCostShort => 'COÛT EST.';

  @override
  String get mockTapShort => 'APPUYER';

  @override
  String get mockMealCajun => 'Riz au poulet à la cajun';

  @override
  String get mockMealSatay => 'Nouilles au tofu et au satay';

  @override
  String get mockMealSweetChilli => 'Boîtes de riz au poulet au piment doux';

  @override
  String get aisleProduce => 'FRUITS ET LÉGUMES';

  @override
  String get aisleMeatFish => 'VIANDE ET POISSON';

  @override
  String get aislePastaRice => 'PÂTES, RIZ ET NOUILLES';

  @override
  String get aisleTinsSauces => 'CONSERVES, BOCAUX ET SAUCES';

  @override
  String get aisleHerbsGrocery => 'HERBES, ÉPICES ET ÉPICERIE';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'l';

  @override
  String get unitTbsp => 'c. à s.';

  @override
  String get unitTsp => 'c. à c.';

  @override
  String unitClove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gousses',
      one: 'gousse',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tranches',
      one: 'tranche',
    );
    return '$_temp0';
  }

  @override
  String unitBunch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bottes',
      one: 'botte',
    );
    return '$_temp0';
  }

  @override
  String unitSprig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'brins',
      one: 'brin',
    );
    return '$_temp0';
  }

  @override
  String unitLeaf(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'feuilles',
      one: 'feuille',
    );
    return '$_temp0';
  }

  @override
  String unitPinch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pincées',
      one: 'pincée',
    );
    return '$_temp0';
  }

  @override
  String unitCan(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'boîtes',
      one: 'boîte',
    );
    return '$_temp0';
  }

  @override
  String unitPack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paquets',
      one: 'paquet',
    );
    return '$_temp0';
  }

  @override
  String get unitToTaste => 'au goût';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get generatingFailed =>
      'Impossible de préparer tes recettes pour le moment.';

  @override
  String get catalogueBuilding => 'On prépare tes recettes…';

  @override
  String get errorCatalogue => 'Impossible de charger tes recettes.';

  @override
  String get errorCatalogueQuota =>
      'La limite de recherche de recettes est atteinte pour aujourd\'hui.';

  @override
  String get errorCatalogueEmpty =>
      'Aucune recette ne correspond à tes préférences.';

  @override
  String get searchReload => 'Relancer la recherche';

  @override
  String get searchLoading => 'Recherche de recettes…';

  @override
  String get filtersFromPreferences =>
      'Tes préférences par défaut, modifiables pour cette recherche';
}
