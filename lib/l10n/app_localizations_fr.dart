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
      'planifie tes dîners selon ton budget,\ntes envies et ce qu\'il y a dans ta cuisine';

  @override
  String get actionContinue => 'continuer';

  @override
  String get actionStart => 'commencer';

  @override
  String get actionGeneratePlan => 'générer le plan';

  @override
  String get haveACode => 'Vous avez un code ?';

  @override
  String get onbLanguageTitle => 'choose your language';

  @override
  String get onbNameTitle => 'comment tu t\'appelles ?';

  @override
  String get onbNamePlaceholder => 'saisis ici';

  @override
  String get onbAgeTitle => 'quel âge as-tu ?';

  @override
  String get onbAgeSubtitle =>
      'nous n\'utilisons ces informations que pour personnaliser ton expérience.';

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
  String get onbGoalTitle => 'qu\'est-ce que tu veux accomplir ?';

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
  String get onbBlockerTitle => 'qu\'est-ce qui t\'en empêche ?';

  @override
  String get blockerNoTime => 'Manque de temps';

  @override
  String get blockerTired => 'Trop fatigué(e) après le travail';

  @override
  String get blockerHard => 'Je trouve la cuisine difficile';

  @override
  String get blockerNoInspiration => 'Je manque d\'inspiration';

  @override
  String get onbInfoPlanningTitle => 'planifier les repas, c\'est chronophage…';

  @override
  String get onbInfoPlanningSubtitle =>
      'on enlève ce stress et te propose de délicieux repas à cuisiner et savourer';

  @override
  String get onbSavingsTitle =>
      'tu as l\'impression de pouvoir économiser plus sur tes courses ?';

  @override
  String get savingsDefinitely => 'Définitivement';

  @override
  String get savingsVeryLikely => 'Très probablement';

  @override
  String get savingsABit => 'Un peu';

  @override
  String get savingsNotReally => 'Pas vraiment';

  @override
  String get onbCookTimeTitle =>
      'combien de temps mets-tu en général à cuisiner ?';

  @override
  String get onbCookTimeSubtitle =>
      'on te proposera des recettes adaptées à ton rythme';

  @override
  String get cookTime15to30 => '15–30 min';

  @override
  String get cookTime30to45 => '30–45 min';

  @override
  String get cookTime45to60 => '45–60 min';

  @override
  String get cookTime60plus => '60+ min';

  @override
  String get onbSourceTitle => 'où as-tu entendu parler de nous ?';

  @override
  String get sourceInstagram => 'Instagram';

  @override
  String get sourceTikTok => 'TikTok';

  @override
  String get sourceYouTube => 'YouTube';

  @override
  String get sourceFacebook => 'Facebook';

  @override
  String get sourceWordOfMouth => 'Bouche à oreille';

  @override
  String get sourceAppStore => 'App Store';

  @override
  String get onbInfoBarsTitle => 'planifie ta semaine plus vite';

  @override
  String get onbInfoBarsSubtitle =>
      'moins de temps à choisir des recettes, fouiller le placard et traîner en rayon';

  @override
  String get onbInfoBarsWithUs => 'avec nous';

  @override
  String get onbInfoBarsWithoutUs => 'sans nous';

  @override
  String get onbInfoBarsWithUsValue => '5 min';

  @override
  String get onbInfoBarsWithoutUsValue => '60 min';

  @override
  String get onbInfoBarsFooter => 'gagne presque une heure\nchaque semaine';

  @override
  String get onbCountryTitle => 'd\'où viens-tu ?';

  @override
  String get onbCountrySubtitle =>
      'on s\'en sert une fois — pour la devise, la cuisine et quelques touches locales';

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
  String get onbEuropeTitle => 'où es-tu en Europe ?';

  @override
  String get onbEuropeSubtitle =>
      'on configure les magasins, la devise et les touches locales';

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
  String get onbStoreTitle => 'choisis ton magasin';

  @override
  String get onbStoreSubtitle => 'on planifie tes courses de la semaine autour';

  @override
  String get onbHouseholdTitle => 'pour combien tu cuisines ?';

  @override
  String get onbHouseholdSubtitle => 'on adapte ton plan et ton budget';

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
  String get onbDaysTitle => 'quels jours tu cuisines ?';

  @override
  String get onbDaysSubtitle => 'choisis les jours avec des repas planifiés';

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
  String get onbBudgetTitle => 'quel est ton budget hebdo ?';

  @override
  String get onbBudgetSubtitle =>
      'choisis ce que tu veux dépenser ces jours-là';

  @override
  String get thisWeek => 'cette semaine';

  @override
  String get onbInfoMoneyTitle => 'tu pourrais économiser\nen moyenne';

  @override
  String get onbInfoMoneySubtitle => 'sur tes courses chaque semaine';

  @override
  String onbInfoMoneyFooter(String amount) {
    return 'soit $amount par an!';
  }

  @override
  String get onbCravingsTitle => 'tu as envie de quoi ?';

  @override
  String get chooseUpToThree => 'choisis jusqu\'à 3';

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
  String get onbDietTitle => 'des régimes alimentaires ?';

  @override
  String get chooseAllThatApply =>
      'choisis toutes les options qui s\'appliquent';

  @override
  String get optionNone => 'Aucun';

  @override
  String get dietVegetarian => 'Végétarien';

  @override
  String get dietVegan => 'Végan';

  @override
  String get dietPescatarian => 'Pescétarien';

  @override
  String get onbAllergiesTitle => 'des allergies ?';

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
  String get onbProteinsTitle => 'qu\'est-ce que tu aimes ?';

  @override
  String get onbProteinsHint => 'choisis les protéines que tu apprécies';

  @override
  String get proteinBeef => 'Bœuf';

  @override
  String get proteinPork => 'Porc';

  @override
  String get proteinChicken => 'Poulet';

  @override
  String get proteinFish => 'Poisson';

  @override
  String get onbAppliancesTitle => 'quels appareils tu as ?';

  @override
  String get onbAppliancesHint => 'choisis au moins un pour planifier';

  @override
  String get applianceMicrowave => 'Micro-ondes';

  @override
  String get applianceHob => 'Plaques';

  @override
  String get applianceOven => 'Four';

  @override
  String get applianceAirFryer => 'Friteuse à air chaud';

  @override
  String get onbTestimonialTitle => 'plébiscité par les cooks du quotidien';

  @override
  String get onbTestimonialSubtitle =>
      'des vraies personnes, de vrais progrès chaque semaine';

  @override
  String get reviewOneName => 'Nicolas';

  @override
  String get reviewOneTitle => 'Nourrir trois avec un petit budget';

  @override
  String get reviewOneBody =>
      'Les recettes ne sont pas fancy mais rassasiantes. On dépense moins chaque semaine.';

  @override
  String get reviewTwoName => 'Léa';

  @override
  String get reviewTwoTitle => 'Dîners rapides après le travail';

  @override
  String get reviewTwoBody =>
      'La plupart des repas prennent moins d\'une demi-heure. C\'est pour ça que je reste.';

  @override
  String get reviewThreeName => 'Thomas';

  @override
  String get reviewThreeTitle => 'De vrais progrès chaque semaine';

  @override
  String get reviewThreeBody =>
      'Simple après quelques réglages, sans conditions ni surprises.';

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
      'accord des repas avec ton magasin et ton budget';

  @override
  String get generatingTaskOrganise => 'organisation des dîners de la semaine';

  @override
  String get generatingTaskShopping => 'création de ta liste de courses';

  @override
  String get generatingTapToContinue => 'appuie pour continuer';

  @override
  String get generatingReady => 'ton plan est prêt';

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
  String get exploreEyebrow => 'RECETTES';

  @override
  String get exploreTitle => 'explorer';

  @override
  String get exploreSearchPlaceholder => 'Rechercher des repas';

  @override
  String get exploreCravings => 'Tes envies';

  @override
  String get exploreSeeLess => 'Voir moins';

  @override
  String get exploreSeeMore => 'Voir plus';

  @override
  String get exploreByCuisine => 'Explorer par cuisine';

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
    return 'Temps de cuisson: $time   |   Portions: $servings';
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
  String get shoppingAddItems => 'Ajouter des courses';

  @override
  String shoppingNeeded(String amount) {
    return '($amount nécessaire)';
  }

  @override
  String get prefsEyebrow => 'TON PLAN';

  @override
  String get prefsTitle => 'préférence';

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
  String get prefsChooseUpToThree => 'Choisis jusqu\'à 3';

  @override
  String get prefsDiet => 'Régimes alimentaires';

  @override
  String get prefsChooseAllThatApply =>
      'Choisis toutes les options qui s\'appliquent';

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
  String get accountEyebrow => 'TON COMPTE';

  @override
  String get accountTitle => 'compte';

  @override
  String get accountSignInApple => 'Se connecter avec Apple';

  @override
  String get accountSignInSub =>
      'Connecte-toi pour enregistrer tes\npréférences dans le cloud.';

  @override
  String get accountFamilyPlan => 'Formule famille';

  @override
  String get accountFamilyPlanSub => 'Partage l\'accès à ton compte.';

  @override
  String get accountInvite => 'Inviter amis et famille';

  @override
  String accountGreeting(String name) {
    return 'Salut, $name';
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
  String get accountRateTably => 'Noter Tably';

  @override
  String get accountSuggestFeature => 'Proposer une fonctionnalité';

  @override
  String get accountLanguage => 'Langue';

  @override
  String get accountResetSaved => 'Réinitialiser les repas enregistrés';

  @override
  String get accountResetSavedSub => 'Vider ta liste de favoris';

  @override
  String get accountResetHistory =>
      'Réinitialiser l\'historique de suggestions';

  @override
  String get accountResetHistorySub =>
      'Des suggestions plus fraîches à la régénération';

  @override
  String get accountSectionAlerts => 'ALERTES';

  @override
  String get accountWeeklyReminder => 'Rappel du plan hebdomadaire';

  @override
  String get accountWeeklyReminderSub =>
      'Dimanche à 10:00 — planifie ta semaine';

  @override
  String get accountSectionHelp => 'AIDE';

  @override
  String get accountShareTably => 'Partager Tably';

  @override
  String get accountContactUs => 'Nous contacter';

  @override
  String get accountManageSubscription => 'Gérer l\'abonnement';

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
  String get tabMenu => 'menu';

  @override
  String get tabRecipes => 'Recettes';

  @override
  String get tabPreferences => 'Préférence';

  @override
  String get tabAccount => 'compte';

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
  String get errorGeneric => 'Une erreur est survenue. Réessaie.';

  @override
  String get errorLoadPlan => 'Impossible de charger ton plan.';

  @override
  String get errorSavePreferences =>
      'Impossible d\'enregistrer tes préférences.';

  @override
  String get errorGeneratePlan => 'Impossible de générer ton plan.';

  @override
  String get errorSignIn => 'Connexion impossible. Réessaie.';

  @override
  String get errorShoppingUpdate => 'Impossible de mettre à jour ta liste.';
}
