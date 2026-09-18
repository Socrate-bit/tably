# Tably

Meal planning around your budget, your cravings and what's already in your kitchen.
Flutter app built to the "Mise App Redesign" specification.

## Running

```bash
flutter pub get
flutter gen-l10n
flutter run
```

PostHog is optional — the app runs without it and logs that analytics are disabled:

```bash
flutter run --dart-define=POSTHOG_API_KEY=phc_your_key
```

## Firebase

| Item | Value |
| --- | --- |
| Project | `tably-9f3c2` ([console](https://console.firebase.google.com/project/tably-9f3c2)) |
| iOS bundle id | `com.appscales.tably` |
| Auth providers | Anonymous, Apple |
| Firestore location | `eur3` |

Everyone is signed in anonymously on first launch so a profile exists immediately;
signing in with Apple *links* that anonymous account, so no data is lost.

Deploy rule changes with:

```bash
firebase deploy --only firestore:rules --project tably-9f3c2
```

### Data model

```
users/{uid}                     profile: name, household, days, budget,
                                country, store, cravings, diets, allergies,
                                proteins, appliances, survey answers
users/{uid}/plan/{day}          one PlannedMeal per cooking day
users/{uid}/shopping/{itemId}   ShoppingItem with its checked state
users/{uid}/recipeState/{id}    favourite, cooked, rating, note, viewedAt
recipes/{recipeId}              shared catalogue (seeded on first launch)
cuisines/{cuisineId}            explore-screen cuisine tiles
```

Every one of these is consumed as a Firestore stream, so a change made on one
device shows up on another without a refresh.

## Architecture

Feature-first, with `model/`, `service/`, `cubit/`, `screen/` and `widget/`
subfolders under each feature.

```
lib/
  main.dart                 Firebase + PostHog bootstrap
  app.dart                  service/cubit wiring, MaterialApp, ScreenUtil
  root.dart                 splash -> onboarding -> home routing; binds uid to cubits
  core/
    theme/                  AppColors, AppTextStyles, AppDimens, AppTheme
    model/                  Weekday and the preference enums
    util/                   Haptics, option label resolution, error banner
    widget/                 shared cards, buttons, photo, check circle
    analytics/              PostHog wrapper + event names
  features/
    onboarding/             24-step flow, rating prompt, generating screen
    plan/                   menu tab, plan generator, weekly plan
    recipe/                 explore tab, recipe detail, catalogue
    shopping/               shopping list
    preferences/            preferences tab, UserProfile
    account/                account tab, auth
    home/                   tab shell
  l10n/                     app_fr.arb (template) + app_en.arb
```

### Conventions

- **State**: Cubit only, never Bloc. All state and logic lives in cubits;
  widgets only render and dispatch.
- **Equality**: every model and state extends `Equatable`.
- **Reactivity**: Firestore streams drive the UI; edits are optimistic and roll
  back on failure (see `ShoppingCubit.toggle`, `RecipeCubit._save`).
- **Theme**: no colour or text style is written inline — everything comes from
  `core/theme/`.
- **Localisation**: all UI copy is in `l10n/`. Persisted values are stable ids
  (`high_protein`, `gluten_free`), resolved to labels via `OptionLabels`.
  Recipe and grocery content is data, and lives in Firestore.
- **Haptics**: every interaction calls `Haptics.tap/toggle/confirm/notify`.
- **Logging**: `debugPrint` with a class tag, e.g. `[PlanCubit]`. Users only see
  UI feedback on errors, never on success.
- **Sizing**: all dimensions, font sizes and spacing go through ScreenUtil,
  against the design's 402x860 frame.

## Adding a language

1. Copy `lib/l10n/app_fr.arb` to `app_<code>.arb` and translate the values.
2. Run `flutter gen-l10n`.
3. Add the language to `_languages` in
   `lib/features/onboarding/widget/steps/language_step.dart`.
