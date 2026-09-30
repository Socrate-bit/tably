import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Tably'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'Planifie tes repas selon ton budget,\ntes envies et ce qu\'il y a dans ta cuisine'**
  String get tagline;

  /// No description provided for @actionContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get actionContinue;

  /// No description provided for @actionStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer →'**
  String get actionStart;

  /// No description provided for @actionGeneratePlan.
  ///
  /// In fr, this message translates to:
  /// **'Générer le plan'**
  String get actionGeneratePlan;

  /// No description provided for @haveACode.
  ///
  /// In fr, this message translates to:
  /// **'Tu as un code ?'**
  String get haveACode;

  /// No description provided for @haveACodeApplied.
  ///
  /// In fr, this message translates to:
  /// **'Code appliqué ✓'**
  String get haveACodeApplied;

  /// No description provided for @onbLanguageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choose your language'**
  String get onbLanguageTitle;

  /// No description provided for @onbNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment tu t\'appelles ?'**
  String get onbNameTitle;

  /// No description provided for @onbNamePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'saisis ici'**
  String get onbNamePlaceholder;

  /// No description provided for @onbAgeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel âge as-tu ?'**
  String get onbAgeTitle;

  /// No description provided for @onbAgeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Nous n\'utilisons ces informations que pour personnaliser ton expérience.'**
  String get onbAgeSubtitle;

  /// No description provided for @ageUnder24.
  ///
  /// In fr, this message translates to:
  /// **'24 ans ou moins'**
  String get ageUnder24;

  /// No description provided for @age25to34.
  ///
  /// In fr, this message translates to:
  /// **'25-34'**
  String get age25to34;

  /// No description provided for @age35to44.
  ///
  /// In fr, this message translates to:
  /// **'35-44'**
  String get age35to44;

  /// No description provided for @age45to54.
  ///
  /// In fr, this message translates to:
  /// **'45-54'**
  String get age45to54;

  /// No description provided for @age55plus.
  ///
  /// In fr, this message translates to:
  /// **'55+'**
  String get age55plus;

  /// No description provided for @onbGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que tu aimerais ?'**
  String get onbGoalTitle;

  /// No description provided for @goalMealPrep.
  ///
  /// In fr, this message translates to:
  /// **'Meal prep pour la semaine'**
  String get goalMealPrep;

  /// No description provided for @goalSimpleRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Trouver des recettes super simples'**
  String get goalSimpleRecipes;

  /// No description provided for @goalTastyRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Trouver des recettes super gourmandes'**
  String get goalTastyRecipes;

  /// No description provided for @goalFeedMyself.
  ///
  /// In fr, this message translates to:
  /// **'Me nourrir'**
  String get goalFeedMyself;

  /// No description provided for @goalFeedFamily.
  ///
  /// In fr, this message translates to:
  /// **'Nourrir ma famille'**
  String get goalFeedFamily;

  /// No description provided for @onbBlockerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quels sont les plus gros obstacles ?'**
  String get onbBlockerTitle;

  /// No description provided for @blockerNoTime.
  ///
  /// In fr, this message translates to:
  /// **'Manque de temps'**
  String get blockerNoTime;

  /// No description provided for @blockerTired.
  ///
  /// In fr, this message translates to:
  /// **'Trop fatigué(e) après le travail'**
  String get blockerTired;

  /// No description provided for @blockerHard.
  ///
  /// In fr, this message translates to:
  /// **'Je trouve la cuisine difficile'**
  String get blockerHard;

  /// No description provided for @blockerNoInspiration.
  ///
  /// In fr, this message translates to:
  /// **'Je manque d\'inspiration'**
  String get blockerNoInspiration;

  /// No description provided for @onbInfoPlanningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifier les repas, c\'est chronophage et ça peut vite coûter cher…'**
  String get onbInfoPlanningTitle;

  /// No description provided for @onbCookTimeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Combien de temps mets-tu en général à cuisiner ?'**
  String get onbCookTimeTitle;

  /// No description provided for @onbCookTimeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On te proposera des recettes adaptées à ton rythme'**
  String get onbCookTimeSubtitle;

  /// No description provided for @cookTime15to30.
  ///
  /// In fr, this message translates to:
  /// **'15–30 min'**
  String get cookTime15to30;

  /// No description provided for @cookTime30to45.
  ///
  /// In fr, this message translates to:
  /// **'30–45 min'**
  String get cookTime30to45;

  /// No description provided for @cookTime45to60.
  ///
  /// In fr, this message translates to:
  /// **'45–60 min'**
  String get cookTime45to60;

  /// No description provided for @cookTime60plus.
  ///
  /// In fr, this message translates to:
  /// **'60+ min'**
  String get cookTime60plus;

  /// No description provided for @onbInfoBarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tably t\'aide à planifier ta semaine'**
  String get onbInfoBarsTitle;

  /// No description provided for @onbInfoBarsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Moins de temps à choisir des recettes, fouiller le placard et traîner en rayon'**
  String get onbInfoBarsSubtitle;

  /// No description provided for @onbInfoBarsWithUs.
  ///
  /// In fr, this message translates to:
  /// **'avec nous'**
  String get onbInfoBarsWithUs;

  /// No description provided for @onbInfoBarsWithoutUs.
  ///
  /// In fr, this message translates to:
  /// **'sans nous'**
  String get onbInfoBarsWithoutUs;

  /// No description provided for @onbInfoBarsWithUsValue.
  ///
  /// In fr, this message translates to:
  /// **'5 min'**
  String get onbInfoBarsWithUsValue;

  /// No description provided for @onbInfoBarsWithoutUsValue.
  ///
  /// In fr, this message translates to:
  /// **'60 min'**
  String get onbInfoBarsWithoutUsValue;

  /// No description provided for @onbInfoBarsFooter.
  ///
  /// In fr, this message translates to:
  /// **'Gagne presque une heure\nchaque semaine'**
  String get onbInfoBarsFooter;

  /// No description provided for @onbCountryTitle.
  ///
  /// In fr, this message translates to:
  /// **'D\'où viens-tu ?'**
  String get onbCountryTitle;

  /// No description provided for @onbCountrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On s\'en sert une fois — pour la devise, la cuisine et quelques touches locales'**
  String get onbCountrySubtitle;

  /// No description provided for @countryUs.
  ///
  /// In fr, this message translates to:
  /// **'États-Unis'**
  String get countryUs;

  /// No description provided for @countryEurope.
  ///
  /// In fr, this message translates to:
  /// **'Europe'**
  String get countryEurope;

  /// No description provided for @countryUk.
  ///
  /// In fr, this message translates to:
  /// **'Royaume-Uni'**
  String get countryUk;

  /// No description provided for @countryAustralia.
  ///
  /// In fr, this message translates to:
  /// **'Australie'**
  String get countryAustralia;

  /// No description provided for @countryCanada.
  ///
  /// In fr, this message translates to:
  /// **'Canada'**
  String get countryCanada;

  /// No description provided for @countryNewZealand.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle-Zélande'**
  String get countryNewZealand;

  /// No description provided for @countryBrazil.
  ///
  /// In fr, this message translates to:
  /// **'Brésil'**
  String get countryBrazil;

  /// No description provided for @onbEuropeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où es-tu en Europe ?'**
  String get onbEuropeTitle;

  /// No description provided for @onbEuropeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On configure les magasins, la devise et les touches locales'**
  String get onbEuropeSubtitle;

  /// No description provided for @countryGermany.
  ///
  /// In fr, this message translates to:
  /// **'Allemagne'**
  String get countryGermany;

  /// No description provided for @countryIreland.
  ///
  /// In fr, this message translates to:
  /// **'Irlande'**
  String get countryIreland;

  /// No description provided for @countrySweden.
  ///
  /// In fr, this message translates to:
  /// **'Suède'**
  String get countrySweden;

  /// No description provided for @countryNetherlands.
  ///
  /// In fr, this message translates to:
  /// **'Pays-Bas'**
  String get countryNetherlands;

  /// No description provided for @countryFrance.
  ///
  /// In fr, this message translates to:
  /// **'France'**
  String get countryFrance;

  /// No description provided for @countrySpain.
  ///
  /// In fr, this message translates to:
  /// **'Espagne'**
  String get countrySpain;

  /// No description provided for @countryRestOfEurope.
  ///
  /// In fr, this message translates to:
  /// **'Reste de l\'Europe'**
  String get countryRestOfEurope;

  /// No description provided for @onbStoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton magasin'**
  String get onbStoreTitle;

  /// No description provided for @onbStoreSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On planifie tes courses de la semaine autour'**
  String get onbStoreSubtitle;

  /// No description provided for @onbHouseholdTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour combien tu cuisines ?'**
  String get onbHouseholdTitle;

  /// No description provided for @onbHouseholdSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On adapte ton plan et ton budget'**
  String get onbHouseholdSubtitle;

  /// No description provided for @peopleCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{personne} other{personnes}}'**
  String peopleCount(int count);

  /// No description provided for @onbDaysTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quels jours tu cuisines ?'**
  String get onbDaysTitle;

  /// No description provided for @onbDaysSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les jours avec des repas planifiés'**
  String get onbDaysSubtitle;

  /// No description provided for @daysSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour sélectionné} other{{count} jours sélectionnés}}'**
  String daysSelected(int count);

  /// No description provided for @onbBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel est ton budget hebdo habituel ?'**
  String get onbBudgetTitle;

  /// No description provided for @onbBudgetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Combien tu veux dépenser cette semaine ?'**
  String get onbBudgetSubtitle;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'cette semaine'**
  String get thisWeek;

  /// No description provided for @onbInfoMoneySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sur les courses chaque semaine, en optimisant tes repas et comparant les prix en magasin'**
  String get onbInfoMoneySubtitle;

  /// No description provided for @onbInfoMoneyFooter.
  ///
  /// In fr, this message translates to:
  /// **'Soit {amount} par an !'**
  String onbInfoMoneyFooter(String amount);

  /// No description provided for @onbCravingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu as envie de quoi ?'**
  String get onbCravingsTitle;

  /// No description provided for @chooseUpToThree.
  ///
  /// In fr, this message translates to:
  /// **'Choisis jusqu\'à 3'**
  String get chooseUpToThree;

  /// No description provided for @cravingQuick.
  ///
  /// In fr, this message translates to:
  /// **'Repas express'**
  String get cravingQuick;

  /// No description provided for @cravingHighProtein.
  ///
  /// In fr, this message translates to:
  /// **'Riche en-protéines'**
  String get cravingHighProtein;

  /// No description provided for @cravingLowCalorie.
  ///
  /// In fr, this message translates to:
  /// **'Peu calorique'**
  String get cravingLowCalorie;

  /// No description provided for @cravingFamilyFavourites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris-familiaux'**
  String get cravingFamilyFavourites;

  /// No description provided for @cravingHealthyComfort.
  ///
  /// In fr, this message translates to:
  /// **'Comfort sain'**
  String get cravingHealthyComfort;

  /// No description provided for @cravingFakeaway.
  ///
  /// In fr, this message translates to:
  /// **'Fakeaway'**
  String get cravingFakeaway;

  /// No description provided for @cravingEasyDigestion.
  ///
  /// In fr, this message translates to:
  /// **'Digestion-facile'**
  String get cravingEasyDigestion;

  /// No description provided for @cravingIndulgent.
  ///
  /// In fr, this message translates to:
  /// **'Gourmand'**
  String get cravingIndulgent;

  /// No description provided for @onbDietTitle.
  ///
  /// In fr, this message translates to:
  /// **'Des régimes alimentaires ?'**
  String get onbDietTitle;

  /// No description provided for @chooseAllThatApply.
  ///
  /// In fr, this message translates to:
  /// **'Choisis toutes les options qui s\'appliquent'**
  String get chooseAllThatApply;

  /// No description provided for @optionNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get optionNone;

  /// No description provided for @dietVegetarian.
  ///
  /// In fr, this message translates to:
  /// **'Végétarien'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In fr, this message translates to:
  /// **'Végan'**
  String get dietVegan;

  /// No description provided for @dietPescatarian.
  ///
  /// In fr, this message translates to:
  /// **'Pescétarien'**
  String get dietPescatarian;

  /// No description provided for @dietHalal.
  ///
  /// In fr, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @onbAllergiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Des allergies ?'**
  String get onbAllergiesTitle;

  /// No description provided for @allergyGlutenFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans gluten'**
  String get allergyGlutenFree;

  /// No description provided for @allergyLactoseFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans lactose'**
  String get allergyLactoseFree;

  /// No description provided for @allergyNutFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans fruits à coque'**
  String get allergyNutFree;

  /// No description provided for @allergyEggFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans œuf'**
  String get allergyEggFree;

  /// No description provided for @allergyShellfishFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans crustacés'**
  String get allergyShellfishFree;

  /// No description provided for @allergySesameFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans sésame'**
  String get allergySesameFree;

  /// No description provided for @allergySoyFree.
  ///
  /// In fr, this message translates to:
  /// **'Sans soja'**
  String get allergySoyFree;

  /// No description provided for @onbProteinsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que tu aimes ?'**
  String get onbProteinsTitle;

  /// No description provided for @onbProteinsHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les protéines que tu apprécies'**
  String get onbProteinsHint;

  /// No description provided for @proteinBeef.
  ///
  /// In fr, this message translates to:
  /// **'Bœuf'**
  String get proteinBeef;

  /// No description provided for @proteinPork.
  ///
  /// In fr, this message translates to:
  /// **'Porc'**
  String get proteinPork;

  /// No description provided for @proteinChicken.
  ///
  /// In fr, this message translates to:
  /// **'Poulet'**
  String get proteinChicken;

  /// No description provided for @proteinFish.
  ///
  /// In fr, this message translates to:
  /// **'Poisson'**
  String get proteinFish;

  /// No description provided for @onbAppliancesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quels appareils tu as ?'**
  String get onbAppliancesTitle;

  /// No description provided for @onbAppliancesHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un pour planifier'**
  String get onbAppliancesHint;

  /// No description provided for @applianceMicrowave.
  ///
  /// In fr, this message translates to:
  /// **'Micro-ondes'**
  String get applianceMicrowave;

  /// No description provided for @applianceHob.
  ///
  /// In fr, this message translates to:
  /// **'Plaques'**
  String get applianceHob;

  /// No description provided for @applianceOven.
  ///
  /// In fr, this message translates to:
  /// **'Four'**
  String get applianceOven;

  /// No description provided for @applianceAirFryer.
  ///
  /// In fr, this message translates to:
  /// **'Friteuse à air chaud'**
  String get applianceAirFryer;

  /// No description provided for @onbTestimonialTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déjà 500 000 personnes ne s\'en passent plus'**
  String get onbTestimonialTitle;

  /// No description provided for @onbTestimonialSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Moins de charge mentale, moins de gaspillage, plus de bons repas'**
  String get onbTestimonialSubtitle;

  /// No description provided for @reviewOneName.
  ///
  /// In fr, this message translates to:
  /// **'Nicolas'**
  String get reviewOneName;

  /// No description provided for @reviewOneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Toute la famille à table, sans exploser le budget'**
  String get reviewOneTitle;

  /// No description provided for @reviewOneBody.
  ///
  /// In fr, this message translates to:
  /// **'Des plats généreux que les enfants finissent, et un ticket de caisse qui baisse chaque semaine. Je ne fais plus mes courses sans Tably.'**
  String get reviewOneBody;

  /// No description provided for @reviewTwoName.
  ///
  /// In fr, this message translates to:
  /// **'Léa'**
  String get reviewTwoName;

  /// No description provided for @reviewTwoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le dîner prêt avant d\'avoir faim'**
  String get reviewTwoTitle;

  /// No description provided for @reviewTwoBody.
  ///
  /// In fr, this message translates to:
  /// **'En rentrant du boulot, je sais déjà quoi cuisiner. 30 minutes max, et c\'est délicieux. Mes soirées sont enfin reposantes.'**
  String get reviewTwoBody;

  /// No description provided for @reviewThreeName.
  ///
  /// In fr, this message translates to:
  /// **'Thomas'**
  String get reviewThreeName;

  /// No description provided for @reviewThreeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fini le « on mange quoi ce soir ? »'**
  String get reviewThreeTitle;

  /// No description provided for @reviewThreeBody.
  ///
  /// In fr, this message translates to:
  /// **'Mon menu de la semaine et ma liste de courses sont prêts en un clic. Je n\'y pense plus, et je mange mieux qu\'avant.'**
  String get reviewThreeBody;

  /// No description provided for @ratingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enjoying Tably?'**
  String get ratingTitle;

  /// No description provided for @ratingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tap a star to rate it on the\nApp Store.'**
  String get ratingSubtitle;

  /// No description provided for @ratingNotNow.
  ///
  /// In fr, this message translates to:
  /// **'Not Now'**
  String get ratingNotNow;

  /// No description provided for @generatingTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name}, on prépare ta semaine'**
  String generatingTitle(String name);

  /// No description provided for @generatingTaskMatch.
  ///
  /// In fr, this message translates to:
  /// **'Accord des repas avec ton magasin et ton budget'**
  String get generatingTaskMatch;

  /// No description provided for @generatingTaskOrganise.
  ///
  /// In fr, this message translates to:
  /// **'Organisation des dîners de la semaine'**
  String get generatingTaskOrganise;

  /// No description provided for @generatingTaskShopping.
  ///
  /// In fr, this message translates to:
  /// **'Création de ta liste de courses'**
  String get generatingTaskShopping;

  /// No description provided for @generatingReady.
  ///
  /// In fr, this message translates to:
  /// **'Ton plan est prêt'**
  String get generatingReady;

  /// No description provided for @defaultChefName.
  ///
  /// In fr, this message translates to:
  /// **'Chef'**
  String get defaultChefName;

  /// No description provided for @plannedFor.
  ///
  /// In fr, this message translates to:
  /// **'prévu pour {store}'**
  String plannedFor(String store);

  /// No description provided for @estimatedCost.
  ///
  /// In fr, this message translates to:
  /// **'COÛT EST.'**
  String get estimatedCost;

  /// No description provided for @tapToView.
  ///
  /// In fr, this message translates to:
  /// **'APPUYER POUR VOIR'**
  String get tapToView;

  /// No description provided for @shoppingList.
  ///
  /// In fr, this message translates to:
  /// **'Liste de courses'**
  String get shoppingList;

  /// No description provided for @shoppingBoughtCount.
  ///
  /// In fr, this message translates to:
  /// **'{done}/{total} achetés'**
  String shoppingBoughtCount(int done, int total);

  /// No description provided for @shoppingDoneCount.
  ///
  /// In fr, this message translates to:
  /// **'{done}/{total} faits'**
  String shoppingDoneCount(int done, int total);

  /// No description provided for @regeneratePlan.
  ///
  /// In fr, this message translates to:
  /// **'régénérer le plan'**
  String get regeneratePlan;

  /// No description provided for @exploreSearchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des repas'**
  String get exploreSearchPlaceholder;

  /// No description provided for @exploreRecent.
  ///
  /// In fr, this message translates to:
  /// **'Consultés récemment'**
  String get exploreRecent;

  /// No description provided for @addRecipeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une recette'**
  String get addRecipeTitle;

  /// No description provided for @addRecipeImportSocial.
  ///
  /// In fr, this message translates to:
  /// **'Importer des réseaux'**
  String get addRecipeImportSocial;

  /// No description provided for @addRecipeImportSocialSub.
  ///
  /// In fr, this message translates to:
  /// **'Depuis Instagram, TikTok ou Facebook'**
  String get addRecipeImportSocialSub;

  /// No description provided for @addRecipeScanFridge.
  ///
  /// In fr, this message translates to:
  /// **'Scanner ton frigo'**
  String get addRecipeScanFridge;

  /// No description provided for @addRecipeScanFridgeSub.
  ///
  /// In fr, this message translates to:
  /// **'On propose des recettes avec ce que tu as'**
  String get addRecipeScanFridgeSub;

  /// No description provided for @addRecipePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Importer une photo'**
  String get addRecipePhoto;

  /// No description provided for @addRecipeText.
  ///
  /// In fr, this message translates to:
  /// **'Importer du texte'**
  String get addRecipeText;

  /// No description provided for @addRecipeLink.
  ///
  /// In fr, this message translates to:
  /// **'Importer un lien'**
  String get addRecipeLink;

  /// No description provided for @addRecipeScratch.
  ///
  /// In fr, this message translates to:
  /// **'Écrire de zéro'**
  String get addRecipeScratch;

  /// No description provided for @recipeMacros.
  ///
  /// In fr, this message translates to:
  /// **'MACROS · PAR PORTION'**
  String get recipeMacros;

  /// No description provided for @macroKcal.
  ///
  /// In fr, this message translates to:
  /// **'kcal'**
  String get macroKcal;

  /// No description provided for @macroProtein.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In fr, this message translates to:
  /// **'Glucides'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In fr, this message translates to:
  /// **'Lipides'**
  String get macroFat;

  /// No description provided for @recipeNotesLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOTES DE RECETTE'**
  String get recipeNotesLabel;

  /// No description provided for @recipeCookTimeAndServings.
  ///
  /// In fr, this message translates to:
  /// **'Temps de cuisson: {time}  |  Portions: {servings}'**
  String recipeCookTimeAndServings(String time, int servings);

  /// No description provided for @recipeMarkCooked.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme cuisiné'**
  String get recipeMarkCooked;

  /// No description provided for @recipeTabIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get recipeTabIngredients;

  /// No description provided for @recipeTabPreparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get recipeTabPreparation;

  /// No description provided for @recipeCookStepByStep.
  ///
  /// In fr, this message translates to:
  /// **'Cuisiner étape par étape'**
  String get recipeCookStepByStep;

  /// No description provided for @recipeYourNotes.
  ///
  /// In fr, this message translates to:
  /// **'Tes notes'**
  String get recipeYourNotes;

  /// No description provided for @recipeNotePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une note à cette recette...'**
  String get recipeNotePlaceholder;

  /// No description provided for @recipeAddToWeek.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au menu de la semaine'**
  String get recipeAddToWeek;

  /// No description provided for @shoppingEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'CETTE SEMAINE'**
  String get shoppingEyebrow;

  /// No description provided for @shoppingCopyList.
  ///
  /// In fr, this message translates to:
  /// **'Copier la liste'**
  String get shoppingCopyList;

  /// No description provided for @shoppingShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shoppingShare;

  /// No description provided for @shoppingAddItems.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des courses'**
  String get shoppingAddItems;

  /// No description provided for @shoppingNeeded.
  ///
  /// In fr, this message translates to:
  /// **'({amount} nécessaire)'**
  String shoppingNeeded(String amount);

  /// No description provided for @prefsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get prefsTitle;

  /// No description provided for @prefsCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get prefsCountry;

  /// No description provided for @prefsStore.
  ///
  /// In fr, this message translates to:
  /// **'Supermarché'**
  String get prefsStore;

  /// No description provided for @prefsHousehold.
  ///
  /// In fr, this message translates to:
  /// **'Taille du foyer'**
  String get prefsHousehold;

  /// No description provided for @prefsHouseholdSub.
  ///
  /// In fr, this message translates to:
  /// **'Pour combien tu cuisines ?'**
  String get prefsHouseholdSub;

  /// No description provided for @prefsCookingDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours de cuisine'**
  String get prefsCookingDays;

  /// No description provided for @prefsCookingDaysSub.
  ///
  /// In fr, this message translates to:
  /// **'Quels jours veux-tu des repas planifiés ?'**
  String get prefsCookingDaysSub;

  /// No description provided for @prefsBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget hebdomadaire'**
  String get prefsBudget;

  /// No description provided for @prefsBudgetForDays.
  ///
  /// In fr, this message translates to:
  /// **' pour {count} jours'**
  String prefsBudgetForDays(int count);

  /// No description provided for @prefsCravings.
  ///
  /// In fr, this message translates to:
  /// **'Envie du moment'**
  String get prefsCravings;

  /// No description provided for @prefsDiet.
  ///
  /// In fr, this message translates to:
  /// **'Régimes alimentaires'**
  String get prefsDiet;

  /// No description provided for @prefsAllergens.
  ///
  /// In fr, this message translates to:
  /// **'Allergènes'**
  String get prefsAllergens;

  /// No description provided for @prefsProteins.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get prefsProteins;

  /// No description provided for @prefsProteinsSub.
  ///
  /// In fr, this message translates to:
  /// **'On orientera ton plan vers les protéines que tu choisis'**
  String get prefsProteinsSub;

  /// No description provided for @prefsAppliances.
  ///
  /// In fr, this message translates to:
  /// **'Appareils de cuisine'**
  String get prefsAppliances;

  /// No description provided for @prefsAppliancesSub.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un pour planifier'**
  String get prefsAppliancesSub;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountTitle;

  /// No description provided for @accountSignInApple.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Apple'**
  String get accountSignInApple;

  /// No description provided for @accountSignInSub.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour enregistrer tes\npréférences dans le cloud.'**
  String get accountSignInSub;

  /// No description provided for @accountFamilyPlan.
  ///
  /// In fr, this message translates to:
  /// **'Formule famille'**
  String get accountFamilyPlan;

  /// No description provided for @accountFamilyPlanSub.
  ///
  /// In fr, this message translates to:
  /// **'Partage l\'accès à ton compte.'**
  String get accountFamilyPlanSub;

  /// No description provided for @accountInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter amis et famille'**
  String get accountInvite;

  /// No description provided for @accountGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Salut, {name} ✎'**
  String accountGreeting(String name);

  /// No description provided for @accountShoppingAt.
  ///
  /// In fr, this message translates to:
  /// **'Courses chez {store}'**
  String accountShoppingAt(String store);

  /// No description provided for @accountActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get accountActive;

  /// No description provided for @accountSectionApp.
  ///
  /// In fr, this message translates to:
  /// **'APP'**
  String get accountSectionApp;

  /// No description provided for @accountRateTably.
  ///
  /// In fr, this message translates to:
  /// **'Noter Tably'**
  String get accountRateTably;

  /// No description provided for @accountSuggestFeature.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une fonctionnalité'**
  String get accountSuggestFeature;

  /// No description provided for @accountLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get accountLanguage;

  /// No description provided for @accountResetSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les repas enregistrés'**
  String get accountResetSaved;

  /// No description provided for @accountResetSavedSub.
  ///
  /// In fr, this message translates to:
  /// **'Vider ta liste de favoris'**
  String get accountResetSavedSub;

  /// No description provided for @accountResetHistory.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'historique de suggestions'**
  String get accountResetHistory;

  /// No description provided for @accountResetHistorySub.
  ///
  /// In fr, this message translates to:
  /// **'Des suggestions plus fraîches à la régénération'**
  String get accountResetHistorySub;

  /// No description provided for @accountSectionAlerts.
  ///
  /// In fr, this message translates to:
  /// **'ALERTES'**
  String get accountSectionAlerts;

  /// No description provided for @accountWeeklyReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel du plan hebdomadaire'**
  String get accountWeeklyReminder;

  /// No description provided for @accountWeeklyReminderSub.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche à 10:00 — planifie ta semaine'**
  String get accountWeeklyReminderSub;

  /// No description provided for @accountSectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'AIDE'**
  String get accountSectionHelp;

  /// No description provided for @accountShareTably.
  ///
  /// In fr, this message translates to:
  /// **'Partager Tably'**
  String get accountShareTably;

  /// No description provided for @accountContactUs.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get accountContactUs;

  /// No description provided for @accountManageSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Gérer l\'abonnement'**
  String get accountManageSubscription;

  /// No description provided for @accountSectionLegal.
  ///
  /// In fr, this message translates to:
  /// **'MENTIONS LÉGALES'**
  String get accountSectionLegal;

  /// No description provided for @accountPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get accountPrivacy;

  /// No description provided for @accountTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get accountTerms;

  /// No description provided for @accountSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get accountSectionAccount;

  /// No description provided for @accountDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get accountDelete;

  /// No description provided for @accountSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get accountSignOut;

  /// No description provided for @accountEnterReferralCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisir un code de parrainage'**
  String get accountEnterReferralCode;

  /// No description provided for @accountSectionCreator.
  ///
  /// In fr, this message translates to:
  /// **'CRÉATEUR'**
  String get accountSectionCreator;

  /// No description provided for @accountReplayOnboarding.
  ///
  /// In fr, this message translates to:
  /// **'Revoir l\'onboarding'**
  String get accountReplayOnboarding;

  /// No description provided for @accountReplayOnboardingSub.
  ///
  /// In fr, this message translates to:
  /// **'Relance le questionnaire depuis le début'**
  String get accountReplayOnboardingSub;

  /// No description provided for @accountPlanFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get accountPlanFree;

  /// No description provided for @accountPlanAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get accountPlanAdmin;

  /// No description provided for @accountPlanUgc.
  ///
  /// In fr, this message translates to:
  /// **'Créateur'**
  String get accountPlanUgc;

  /// No description provided for @referralTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de parrainage'**
  String get referralTitle;

  /// No description provided for @referralSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code pour débloquer l\'accès.'**
  String get referralSubtitle;

  /// No description provided for @referralPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'TON CODE'**
  String get referralPlaceholder;

  /// No description provided for @referralSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get referralSubmit;

  /// No description provided for @referralCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get referralCancel;

  /// No description provided for @referralInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get referralInvalid;

  /// No description provided for @referralLimit.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a atteint sa limite d\'utilisation'**
  String get referralLimit;

  /// No description provided for @referralAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà utilisé ce code'**
  String get referralAlreadyUsed;

  /// No description provided for @referralError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue, réessaie'**
  String get referralError;

  /// No description provided for @tabMenu.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get tabMenu;

  /// No description provided for @tabRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get tabRecipes;

  /// No description provided for @tabPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférence'**
  String get tabPreferences;

  /// No description provided for @tabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get tabAccount;

  /// No description provided for @dayMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get daySunday;

  /// No description provided for @dayShortMonday.
  ///
  /// In fr, this message translates to:
  /// **'L'**
  String get dayShortMonday;

  /// No description provided for @dayShortTuesday.
  ///
  /// In fr, this message translates to:
  /// **'M'**
  String get dayShortTuesday;

  /// No description provided for @dayShortWednesday.
  ///
  /// In fr, this message translates to:
  /// **'M'**
  String get dayShortWednesday;

  /// No description provided for @dayShortThursday.
  ///
  /// In fr, this message translates to:
  /// **'J'**
  String get dayShortThursday;

  /// No description provided for @dayShortFriday.
  ///
  /// In fr, this message translates to:
  /// **'V'**
  String get dayShortFriday;

  /// No description provided for @dayShortSaturday.
  ///
  /// In fr, this message translates to:
  /// **'S'**
  String get dayShortSaturday;

  /// No description provided for @dayShortSunday.
  ///
  /// In fr, this message translates to:
  /// **'D'**
  String get dayShortSunday;

  /// No description provided for @errorSavePreferences.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer tes préférences.'**
  String get errorSavePreferences;

  /// No description provided for @errorGeneratePlan.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer ton plan.'**
  String get errorGeneratePlan;

  /// No description provided for @errorSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Réessaie.'**
  String get errorSignIn;

  /// No description provided for @errorShoppingUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour ta liste.'**
  String get errorShoppingUpdate;

  /// No description provided for @blockerSaving.
  ///
  /// In fr, this message translates to:
  /// **'J\'essaye de faire des économies'**
  String get blockerSaving;

  /// No description provided for @onbInfoMoneyEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'AVEC TABLY, ON ÉCONOMISE EN MOYENNE'**
  String get onbInfoMoneyEyebrow;

  /// No description provided for @onbInfoMoneyPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'par semaine'**
  String get onbInfoMoneyPerWeek;

  /// No description provided for @onbPlanStartTitle.
  ///
  /// In fr, this message translates to:
  /// **'On attaque ton plan de la semaine'**
  String get onbPlanStartTitle;

  /// No description provided for @onbPlanStartSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques questions sur ta cuisine et ton budget, et ton plan est prêt.'**
  String get onbPlanStartSubtitle;

  /// No description provided for @onbMealsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Combien de repas par jour ?'**
  String get onbMealsTitle;

  /// No description provided for @onbMealsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On adapte ton plan à ton rythme'**
  String get onbMealsSubtitle;

  /// No description provided for @mealsPerDayOption.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 repas par jour} other{{count} repas par jour}}'**
  String mealsPerDayOption(int count);

  /// No description provided for @mealsPerDayDinnerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Dîner seulement'**
  String get mealsPerDayDinnerOnly;

  /// No description provided for @mealsPerDayLunchDinner.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner + dîner'**
  String get mealsPerDayLunchDinner;

  /// No description provided for @onbDiversityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Combien de variété ?'**
  String get onbDiversityTitle;

  /// No description provided for @onbDiversitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On réutilise certains plats en restes pour t\'éviter de cuisiner tous les jours'**
  String get onbDiversitySubtitle;

  /// No description provided for @diversityAllDifferent.
  ///
  /// In fr, this message translates to:
  /// **'On cuisine à chaque repas'**
  String get diversityAllDifferent;

  /// No description provided for @varietyHigh.
  ///
  /// In fr, this message translates to:
  /// **'Un max de variété'**
  String get varietyHigh;

  /// No description provided for @varietyBalanced.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get varietyBalanced;

  /// No description provided for @varietyLow.
  ///
  /// In fr, this message translates to:
  /// **'Batch cooking'**
  String get varietyLow;

  /// No description provided for @diversityDetailReuse.
  ///
  /// In fr, this message translates to:
  /// **'Seulement {recipes} recettes à cuisiner pour {slots} repas'**
  String diversityDetailReuse(int recipes, int slots);

  /// No description provided for @slotLunch.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get slotLunch;

  /// No description provided for @slotDinner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get slotDinner;

  /// No description provided for @switchEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'BONNE NOUVELLE'**
  String get switchEyebrow;

  /// No description provided for @switchTitlePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Tes recettes coûteraient '**
  String get switchTitlePrefix;

  /// No description provided for @switchTitleHighlight.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % moins cher'**
  String switchTitleHighlight(int percent);

  /// No description provided for @switchTitleSuffix.
  ///
  /// In fr, this message translates to:
  /// **' chez {store}'**
  String switchTitleSuffix(String store);

  /// No description provided for @switchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'D\'après ton profil et ton panier de la semaine. Tu peux changer maintenant ou garder {store}.'**
  String switchSubtitle(String store);

  /// No description provided for @switchAccept.
  ///
  /// In fr, this message translates to:
  /// **'Passer à {store}'**
  String switchAccept(String store);

  /// No description provided for @switchDecline.
  ///
  /// In fr, this message translates to:
  /// **'Garder {store}'**
  String switchDecline(String store);

  /// No description provided for @budgetSavings.
  ///
  /// In fr, this message translates to:
  /// **'{amount} d\'économie 🎉'**
  String budgetSavings(String amount);

  /// No description provided for @planCounts.
  ///
  /// In fr, this message translates to:
  /// **'{slots} repas · {recipes} recettes à cuisiner'**
  String planCounts(int slots, int recipes);

  /// No description provided for @leftoverBadge.
  ///
  /// In fr, this message translates to:
  /// **'♻ Reste'**
  String get leftoverBadge;

  /// No description provided for @regeneratingPlan.
  ///
  /// In fr, this message translates to:
  /// **'nouveau plan en cours…'**
  String get regeneratingPlan;

  /// No description provided for @storesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supermarché'**
  String get storesTitle;

  /// No description provided for @storesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prix estimé de ton plan cette semaine'**
  String get storesSubtitle;

  /// No description provided for @storesCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Ton magasin actuel'**
  String get storesCurrent;

  /// No description provided for @storesCheaper.
  ///
  /// In fr, this message translates to:
  /// **'{amount} de moins que {store}'**
  String storesCheaper(String amount, String store);

  /// No description provided for @storesPricier.
  ///
  /// In fr, this message translates to:
  /// **'{amount} de plus'**
  String storesPricier(String amount);

  /// No description provided for @storesCurrentTag.
  ///
  /// In fr, this message translates to:
  /// **'ACTUEL'**
  String get storesCurrentTag;

  /// No description provided for @storesFootnote.
  ///
  /// In fr, this message translates to:
  /// **'Les prix sont estimés à partir des {count} recettes de ta semaine et des relevés en magasin.'**
  String storesFootnote(int count);

  /// No description provided for @recipesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get recipesTitle;

  /// No description provided for @searchResultCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 résultat} other{{count} résultats}}'**
  String searchResultCount(int count);

  /// No description provided for @searchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun repas ne correspond à « {query} ».\nEssaie un ingrédient ou un type de plat.'**
  String searchEmpty(String query);

  /// No description provided for @recipesAll.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get recipesAll;

  /// No description provided for @filtersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette ne correspond à ces filtres.'**
  String get filtersEmpty;

  /// No description provided for @filtersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtersTitle;

  /// No description provided for @filtersReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get filtersReset;

  /// No description provided for @filtersCravings.
  ///
  /// In fr, this message translates to:
  /// **'Tes envies'**
  String get filtersCravings;

  /// No description provided for @filtersCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine type'**
  String get filtersCuisine;

  /// No description provided for @filtersProtein.
  ///
  /// In fr, this message translates to:
  /// **'Préférence'**
  String get filtersProtein;

  /// No description provided for @filtersProteinSub.
  ///
  /// In fr, this message translates to:
  /// **'Le type de viande ou de protéine que tu veux voir'**
  String get filtersProteinSub;

  /// No description provided for @filtersPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix par portion'**
  String get filtersPrice;

  /// No description provided for @filtersPriceRange.
  ///
  /// In fr, this message translates to:
  /// **'{min} – {max}'**
  String filtersPriceRange(String min, String max);

  /// No description provided for @filtersPriceAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les recettes'**
  String get filtersPriceAll;

  /// No description provided for @filtersPriceUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Recettes jusqu\'à {amount} par portion'**
  String filtersPriceUpTo(String amount);

  /// No description provided for @filtersApply.
  ///
  /// In fr, this message translates to:
  /// **'Voir les recettes'**
  String get filtersApply;

  /// No description provided for @proteinTofu.
  ///
  /// In fr, this message translates to:
  /// **'Tofu'**
  String get proteinTofu;

  /// No description provided for @cuisineItalian.
  ///
  /// In fr, this message translates to:
  /// **'Italienne'**
  String get cuisineItalian;

  /// No description provided for @cuisineItalianDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pasta • Risotto • Gnocchi'**
  String get cuisineItalianDesc;

  /// No description provided for @cuisineAsian.
  ///
  /// In fr, this message translates to:
  /// **'Asiatique'**
  String get cuisineAsian;

  /// No description provided for @cuisineAsianDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nouilles • Curry • Sauté'**
  String get cuisineAsianDesc;

  /// No description provided for @cuisineMexican.
  ///
  /// In fr, this message translates to:
  /// **'Mexicaine'**
  String get cuisineMexican;

  /// No description provided for @cuisineMexicanDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tacos • Burritos • Fajitas'**
  String get cuisineMexicanDesc;

  /// No description provided for @cuisineIndian.
  ///
  /// In fr, this message translates to:
  /// **'Indienne'**
  String get cuisineIndian;

  /// No description provided for @cuisineIndianDesc.
  ///
  /// In fr, this message translates to:
  /// **'Curry • Tikka • Tandoori'**
  String get cuisineIndianDesc;

  /// No description provided for @cuisineMediterranean.
  ///
  /// In fr, this message translates to:
  /// **'Méditerranéenne'**
  String get cuisineMediterranean;

  /// No description provided for @cuisineMediterraneanDesc.
  ///
  /// In fr, this message translates to:
  /// **'Gyros • Halloumi • Falafel'**
  String get cuisineMediterraneanDesc;

  /// No description provided for @favouritesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favouritesTitle;

  /// No description provided for @favouritesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 recette enregistrée} other{{count} recettes enregistrées}}'**
  String favouritesCount(int count);

  /// No description provided for @favouritesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour l\'instant.\nAppuie sur le cœur d\'une recette pour l\'enregistrer.'**
  String get favouritesEmpty;

  /// No description provided for @replaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer par'**
  String get replaceTitle;

  /// No description provided for @replaceSubtitleSlot.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le plat qui remplace celui de {day}'**
  String replaceSubtitleSlot(String day);

  /// No description provided for @replaceSubtitleWeek.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le plat qui prend sa place dans la semaine'**
  String get replaceSubtitleWeek;

  /// No description provided for @replaceAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get replaceAll;

  /// No description provided for @replaceFavourites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get replaceFavourites;

  /// No description provided for @replaceEmptyFavourites.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour l\'instant.'**
  String get replaceEmptyFavourites;

  /// No description provided for @replaceEmptySearch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun repas ne correspond à cette recherche.'**
  String get replaceEmptySearch;

  /// No description provided for @recipeCreatedBy.
  ///
  /// In fr, this message translates to:
  /// **'RECETTE DE'**
  String get recipeCreatedBy;

  /// No description provided for @recipeReplaceMeal.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer ce repas'**
  String get recipeReplaceMeal;

  /// No description provided for @prefsMealsPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Repas par jour'**
  String get prefsMealsPerDay;

  /// No description provided for @prefsMealsPerDaySub.
  ///
  /// In fr, this message translates to:
  /// **'Les plats sont réutilisés en restes pour limiter le nombre de recettes'**
  String get prefsMealsPerDaySub;

  /// No description provided for @prefsVariety.
  ///
  /// In fr, this message translates to:
  /// **'Variété'**
  String get prefsVariety;

  /// No description provided for @mockCostShort.
  ///
  /// In fr, this message translates to:
  /// **'COÛT EST.'**
  String get mockCostShort;

  /// No description provided for @mockTapShort.
  ///
  /// In fr, this message translates to:
  /// **'APPUYER'**
  String get mockTapShort;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'fr':
      return AppL10nFr();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
