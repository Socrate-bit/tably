# Tably

Meal planning around your budget, your cravings and what's already in your kitchen.
Flutter app built to the "Mise App Redesign" specification.

## Running

```bash
flutter pub get
flutter gen-l10n
flutter run
```

Mixpanel tracks to the Tably project by default; point it at another project with:

```bash
flutter run --dart-define=MIXPANEL_TOKEN=your_token
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

### Recipes: Spoonacular + Gemini

Each user's recipes are built from their onboarding answers, at the end of
onboarding and again whenever a preference they depend on changes (diets,
allergies, proteins, appliances, cook time, language):

1. The `searchRecipes` Cloud Function (`functions/src/index.ts`) queries
   Spoonacular's `complexSearch` through RapidAPI and trims the results. The key
   stays server-side as a secret. **Every build spends one request of the daily
   quota (40 on the free plan) — there is no cache yet.** Reshuffling the week
   or swapping a meal never calls it.
2. `RecipeAiService` sends the candidates to Gemini (`gemini-3.1-flash-lite`,
   Firebase AI Logic, Gemini Developer API) in parallel chunks. Gemini drops any
   recipe that breaks a diet, allergy, protein or appliance constraint, and
   translates the rest into the user's language. Numbers, photos and sources
   always come from Spoonacular, never from the model.
3. `CatalogueCubit` stores the result at `users/{uid}/recipes`. The plan and the
   shopping list are derived from it.

Set the key and deploy the function:

```bash
firebase functions:secrets:set SPOONACULAR_API_KEY --project tably-9f3c2
firebase deploy --only functions:searchRecipes --project tably-9f3c2
# The org policy blocks public invokers, so the deploy reports an IAM error;
# the function is deployed, it just needs this once per new function:
gcloud run services update searchrecipes --region europe-west1 --project tably-9f3c2 --no-invoker-iam-check
```

For the emulator, put `SPOONACULAR_API_KEY=...` in `functions/.secret.local`
(ignored by git). Quota use is logged on every call:
`firebase functions:log --only searchRecipes`.

App Check is not enforced yet, so the Gemini endpoint is reachable by anyone
holding the app's Firebase config; enable it before release.

### AI chef (chat)

The chef button beside the tab bar opens a chat with an AI chef that can act on
the whole app. `ChatCubit` runs a Gemini conversation (`gemini-3.5-flash`,
Firebase AI Logic) with function calling, and the tools in
`features/chat/tool/` call the same cubit methods a tap would:

- **Reads** (week, preferences, recipes, history, shopping list, store prices)
  run at once.
- **Spoonacular** calls (search, "what can I make with…", similar recipes,
  import from a URL, ingredient substitutes, wine pairing) go through the
  `spoonacular` Cloud Function, which caps each user at 10 requests a day in
  `agentQuota/{uid}` so the chat can't spend the app's shared quota.
- **Changes** (regenerate the week or a meal, swap meals, preferences
  including the user's own free-text rules, favourites and ratings, the
  shopping list, writing a recipe or deriving one from another) are shown as
  cards the user approves or declines; nothing runs before that.

Recipes the chef writes are stored with the catalogue (`origin: chef`) and
survive rebuilds. Only recipes a build fetched are dealt into the week, so
adding one never reshuffles it. The user's own rules (`customPreferences`) are
checked by Gemini as strictly as allergies.

Deploy the function like `searchRecipes`:

```bash
firebase deploy --only functions:spoonacular --project tably-9f3c2
gcloud run services update spoonacular --region europe-west1 --project tably-9f3c2 --no-invoker-iam-check
```

### Data model

```
users/{uid}                     profile: name, household, meals per day, days,
                                budget, country, store, cravings, diets,
                                allergies, proteins, appliances, survey answers
users/{uid}/plan/week           plan settings: shuffle seed + swapped meals
users/{uid}/plan/catalogue      key of the preferences the recipes were built for
users/{uid}/recipes/{id}        Recipe, id = Spoonacular id, text in the user's language
users/{uid}/shopping/{itemId}   ShoppingItem derived from the week or added by the user,
                                with its checked, removed and edited state
users/{uid}/recipeState/{id}    favourite, cooked, rating, note, viewedAt
users/{uid}/chat/{messageId}    the conversation with the AI chef and its proposals
agentQuota/{uid}                the AI chef's Spoonacular requests today (server only)
```

The week itself is never stored. `WeekPlanner` derives it from the profile
(cooking days, meals per day), the user's recipes and the plan settings, so changing a preference
reflows the menu instantly and every device shows the same week. It reproduces
the design prototype's algorithm exactly — `test/week_planner_test.dart` checks
45 configurations against fixtures generated from the prototype itself.

The shopping list is derived from the week too (`ShoppingListBuilder`): every
portion eaten, for the whole household, merged per ingredient and grouped by
aisle. It is rewritten when the week or the household changes; ticks,
deletions and edits survive, and items the user added are never touched.

## Architecture

Feature-first, with `model/`, `service/`, `cubit/`, `screen/` and `widget/`
subfolders under each feature.

```
lib/
  main.dart                 Firebase + Mixpanel bootstrap
  app.dart                  service/cubit wiring, MaterialApp, ScreenUtil
  root.dart                 splash -> onboarding -> home routing; binds uid to cubits
  core/
    theme/                  AppColors, AppTextStyles, AppDimens, AppTheme
    model/                  Weekday and the preference enums
    util/                   Haptics, option label resolution, error banner
    widget/                 shared cards, buttons, photo, check circle
    analytics/              Mixpanel wrapper + event names
  features/
    onboarding/             24-step flow, rating prompt, generating screen
    plan/                   week tab, week planner, supermarket comparison
    recipe/                 recipes tab, filters, favourites, recipe detail,
                            replace sheet, catalogue (Spoonacular + Gemini)
    shopping/               shopping list
    chat/                   AI chef: chat screen, Gemini session, tools (tool/)
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
  back on failure (see `ShoppingCubit.toggle`, `RecipeCubit._save`,
  `PlanCubit._apply`).
- **Theme**: no colour or text style is written inline — everything comes from
  `core/theme/`.
- **Localisation**: all UI copy is in `l10n/`. Persisted values are stable ids
  (`high_protein`, `gluten_free`), resolved to labels via `OptionLabels`.
  Recipe and grocery content is data: it lives in Firestore, already in the
  user's language.
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
