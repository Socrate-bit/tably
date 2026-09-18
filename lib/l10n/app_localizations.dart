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
  /// **'planifie tes dîners selon ton budget,\ntes envies et ce qu\'il y a dans ta cuisine'**
  String get tagline;

  /// No description provided for @actionContinue.
  ///
  /// In fr, this message translates to:
  /// **'continuer'**
  String get actionContinue;

  /// No description provided for @actionStart.
  ///
  /// In fr, this message translates to:
  /// **'commencer'**
  String get actionStart;

  /// No description provided for @actionGeneratePlan.
  ///
  /// In fr, this message translates to:
  /// **'générer le plan'**
  String get actionGeneratePlan;

  /// No description provided for @haveACode.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez un code ?'**
  String get haveACode;

  /// No description provided for @onbLanguageTitle.
  ///
  /// In fr, this message translates to:
  /// **'choose your language'**
  String get onbLanguageTitle;

  /// No description provided for @onbNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'comment tu t\'appelles ?'**
  String get onbNameTitle;

  /// No description provided for @onbNamePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'saisis ici'**
  String get onbNamePlaceholder;

  /// No description provided for @onbAgeTitle.
  ///
  /// In fr, this message translates to:
  /// **'quel âge as-tu ?'**
  String get onbAgeTitle;

  /// No description provided for @onbAgeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'nous n\'utilisons ces informations que pour personnaliser ton expérience.'**
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
  /// **'qu\'est-ce que tu veux accomplir ?'**
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
  /// **'qu\'est-ce qui t\'en empêche ?'**
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
  /// **'planifier les repas, c\'est chronophage…'**
  String get onbInfoPlanningTitle;

  /// No description provided for @onbInfoPlanningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'on enlève ce stress et te propose de délicieux repas à cuisiner et savourer'**
  String get onbInfoPlanningSubtitle;

  /// No description provided for @onbSavingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'tu as l\'impression de pouvoir économiser plus sur tes courses ?'**
  String get onbSavingsTitle;

  /// No description provided for @savingsDefinitely.
  ///
  /// In fr, this message translates to:
  /// **'Définitivement'**
  String get savingsDefinitely;

  /// No description provided for @savingsVeryLikely.
  ///
  /// In fr, this message translates to:
  /// **'Très probablement'**
  String get savingsVeryLikely;

  /// No description provided for @savingsABit.
  ///
  /// In fr, this message translates to:
  /// **'Un peu'**
  String get savingsABit;

  /// No description provided for @savingsNotReally.
  ///
  /// In fr, this message translates to:
  /// **'Pas vraiment'**
  String get savingsNotReally;

  /// No description provided for @onbCookTimeTitle.
  ///
  /// In fr, this message translates to:
  /// **'combien de temps mets-tu en général à cuisiner ?'**
  String get onbCookTimeTitle;

  /// No description provided for @onbCookTimeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'on te proposera des recettes adaptées à ton rythme'**
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

  /// No description provided for @onbSourceTitle.
  ///
  /// In fr, this message translates to:
  /// **'où as-tu entendu parler de nous ?'**
  String get onbSourceTitle;

  /// No description provided for @sourceInstagram.
  ///
  /// In fr, this message translates to:
  /// **'Instagram'**
  String get sourceInstagram;

  /// No description provided for @sourceTikTok.
  ///
  /// In fr, this message translates to:
  /// **'TikTok'**
  String get sourceTikTok;

  /// No description provided for @sourceYouTube.
  ///
  /// In fr, this message translates to:
  /// **'YouTube'**
  String get sourceYouTube;

  /// No description provided for @sourceFacebook.
  ///
  /// In fr, this message translates to:
  /// **'Facebook'**
  String get sourceFacebook;

  /// No description provided for @sourceWordOfMouth.
  ///
  /// In fr, this message translates to:
  /// **'Bouche à oreille'**
  String get sourceWordOfMouth;

  /// No description provided for @sourceAppStore.
  ///
  /// In fr, this message translates to:
  /// **'App Store'**
  String get sourceAppStore;

  /// No description provided for @onbInfoBarsTitle.
  ///
  /// In fr, this message translates to:
  /// **'planifie ta semaine plus vite'**
  String get onbInfoBarsTitle;

  /// No description provided for @onbInfoBarsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'moins de temps à choisir des recettes, fouiller le placard et traîner en rayon'**
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
  /// **'gagne presque une heure\nchaque semaine'**
  String get onbInfoBarsFooter;

  /// No description provided for @onbCountryTitle.
  ///
  /// In fr, this message translates to:
  /// **'d\'où viens-tu ?'**
  String get onbCountryTitle;

  /// No description provided for @onbCountrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'on s\'en sert une fois — pour la devise, la cuisine et quelques touches locales'**
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
  /// **'où es-tu en Europe ?'**
  String get onbEuropeTitle;

  /// No description provided for @onbEuropeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'on configure les magasins, la devise et les touches locales'**
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
  /// **'choisis ton magasin'**
  String get onbStoreTitle;

  /// No description provided for @onbStoreSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'on planifie tes courses de la semaine autour'**
  String get onbStoreSubtitle;

  /// No description provided for @onbHouseholdTitle.
  ///
  /// In fr, this message translates to:
  /// **'pour combien tu cuisines ?'**
  String get onbHouseholdTitle;

  /// No description provided for @onbHouseholdSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'on adapte ton plan et ton budget'**
  String get onbHouseholdSubtitle;

  /// No description provided for @peopleCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{personne} other{personnes}}'**
  String peopleCount(int count);

  /// No description provided for @onbDaysTitle.
  ///
  /// In fr, this message translates to:
  /// **'quels jours tu cuisines ?'**
  String get onbDaysTitle;

  /// No description provided for @onbDaysSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'choisis les jours avec des repas planifiés'**
  String get onbDaysSubtitle;

  /// No description provided for @daysSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour sélectionné} other{{count} jours sélectionnés}}'**
  String daysSelected(int count);

  /// No description provided for @onbBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'quel est ton budget hebdo ?'**
  String get onbBudgetTitle;

  /// No description provided for @onbBudgetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'choisis ce que tu veux dépenser ces jours-là'**
  String get onbBudgetSubtitle;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'cette semaine'**
  String get thisWeek;

  /// No description provided for @onbInfoMoneyTitle.
  ///
  /// In fr, this message translates to:
  /// **'tu pourrais économiser\nen moyenne'**
  String get onbInfoMoneyTitle;

  /// No description provided for @onbInfoMoneySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'sur tes courses chaque semaine'**
  String get onbInfoMoneySubtitle;

  /// No description provided for @onbInfoMoneyFooter.
  ///
  /// In fr, this message translates to:
  /// **'soit {amount} par an!'**
  String onbInfoMoneyFooter(String amount);

  /// No description provided for @onbCravingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'tu as envie de quoi ?'**
  String get onbCravingsTitle;

  /// No description provided for @chooseUpToThree.
  ///
  /// In fr, this message translates to:
  /// **'choisis jusqu\'à 3'**
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
  /// **'des régimes alimentaires ?'**
  String get onbDietTitle;

  /// No description provided for @chooseAllThatApply.
  ///
  /// In fr, this message translates to:
  /// **'choisis toutes les options qui s\'appliquent'**
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

  /// No description provided for @onbAllergiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'des allergies ?'**
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
  /// **'qu\'est-ce que tu aimes ?'**
  String get onbProteinsTitle;

  /// No description provided for @onbProteinsHint.
  ///
  /// In fr, this message translates to:
  /// **'choisis les protéines que tu apprécies'**
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
  /// **'quels appareils tu as ?'**
  String get onbAppliancesTitle;

  /// No description provided for @onbAppliancesHint.
  ///
  /// In fr, this message translates to:
  /// **'choisis au moins un pour planifier'**
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
  /// **'plébiscité par les cooks du quotidien'**
  String get onbTestimonialTitle;

  /// No description provided for @onbTestimonialSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'des vraies personnes, de vrais progrès chaque semaine'**
  String get onbTestimonialSubtitle;

  /// No description provided for @reviewOneName.
  ///
  /// In fr, this message translates to:
  /// **'Nicolas'**
  String get reviewOneName;

  /// No description provided for @reviewOneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nourrir trois avec un petit budget'**
  String get reviewOneTitle;

  /// No description provided for @reviewOneBody.
  ///
  /// In fr, this message translates to:
  /// **'Les recettes ne sont pas fancy mais rassasiantes. On dépense moins chaque semaine.'**
  String get reviewOneBody;

  /// No description provided for @reviewTwoName.
  ///
  /// In fr, this message translates to:
  /// **'Léa'**
  String get reviewTwoName;

  /// No description provided for @reviewTwoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dîners rapides après le travail'**
  String get reviewTwoTitle;

  /// No description provided for @reviewTwoBody.
  ///
  /// In fr, this message translates to:
  /// **'La plupart des repas prennent moins d\'une demi-heure. C\'est pour ça que je reste.'**
  String get reviewTwoBody;

  /// No description provided for @reviewThreeName.
  ///
  /// In fr, this message translates to:
  /// **'Thomas'**
  String get reviewThreeName;

  /// No description provided for @reviewThreeTitle.
  ///
  /// In fr, this message translates to:
  /// **'De vrais progrès chaque semaine'**
  String get reviewThreeTitle;

  /// No description provided for @reviewThreeBody.
  ///
  /// In fr, this message translates to:
  /// **'Simple après quelques réglages, sans conditions ni surprises.'**
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
  /// **'accord des repas avec ton magasin et ton budget'**
  String get generatingTaskMatch;

  /// No description provided for @generatingTaskOrganise.
  ///
  /// In fr, this message translates to:
  /// **'organisation des dîners de la semaine'**
  String get generatingTaskOrganise;

  /// No description provided for @generatingTaskShopping.
  ///
  /// In fr, this message translates to:
  /// **'création de ta liste de courses'**
  String get generatingTaskShopping;

  /// No description provided for @generatingTapToContinue.
  ///
  /// In fr, this message translates to:
  /// **'appuie pour continuer'**
  String get generatingTapToContinue;

  /// No description provided for @generatingReady.
  ///
  /// In fr, this message translates to:
  /// **'ton plan est prêt'**
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

  /// No description provided for @exploreEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'RECETTES'**
  String get exploreEyebrow;

  /// No description provided for @exploreTitle.
  ///
  /// In fr, this message translates to:
  /// **'explorer'**
  String get exploreTitle;

  /// No description provided for @exploreSearchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des repas'**
  String get exploreSearchPlaceholder;

  /// No description provided for @exploreCravings.
  ///
  /// In fr, this message translates to:
  /// **'Tes envies'**
  String get exploreCravings;

  /// No description provided for @exploreSeeLess.
  ///
  /// In fr, this message translates to:
  /// **'Voir moins'**
  String get exploreSeeLess;

  /// No description provided for @exploreSeeMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get exploreSeeMore;

  /// No description provided for @exploreByCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Explorer par cuisine'**
  String get exploreByCuisine;

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
  /// **'Temps de cuisson: {time}   |   Portions: {servings}'**
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

  /// No description provided for @prefsEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'TON PLAN'**
  String get prefsEyebrow;

  /// No description provided for @prefsTitle.
  ///
  /// In fr, this message translates to:
  /// **'préférence'**
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

  /// No description provided for @prefsChooseUpToThree.
  ///
  /// In fr, this message translates to:
  /// **'Choisis jusqu\'à 3'**
  String get prefsChooseUpToThree;

  /// No description provided for @prefsDiet.
  ///
  /// In fr, this message translates to:
  /// **'Régimes alimentaires'**
  String get prefsDiet;

  /// No description provided for @prefsChooseAllThatApply.
  ///
  /// In fr, this message translates to:
  /// **'Choisis toutes les options qui s\'appliquent'**
  String get prefsChooseAllThatApply;

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

  /// No description provided for @accountEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'TON COMPTE'**
  String get accountEyebrow;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'compte'**
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
  /// **'Salut, {name}'**
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

  /// No description provided for @tabMenu.
  ///
  /// In fr, this message translates to:
  /// **'menu'**
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
  /// **'compte'**
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

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get errorGeneric;

  /// No description provided for @errorLoadPlan.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ton plan.'**
  String get errorLoadPlan;

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
