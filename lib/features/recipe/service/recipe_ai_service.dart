import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../../core/model/preference_option.dart';
import '../../preferences/model/user_profile.dart';
import '../model/recipe.dart';

/// Thrown when Gemini rejects every candidate, so there is nothing to plan.
class NoMatchingRecipesException implements Exception {
  const NoMatchingRecipesException(this.rejected);

  final int rejected;

  @override
  String toString() => 'NoMatchingRecipesException($rejected rejected)';
}

/// Checks Spoonacular candidates against the user's constraints and adapts
/// the survivors with Gemini: translation, craving, protein, cuisine, emoji,
/// unit and aisle. Numbers, photos and sources always come from Spoonacular.
class RecipeAiService {
  static const model = 'gemini-3.1-flash-lite';

  /// Recipes per Gemini call. Small chunks keep each answer short and fast,
  /// and a failed chunk only loses these few.
  static const chunkSize = 4;

  /// Adapts [raw] recipes for [profile]. Chunks run in parallel; a failed
  /// chunk is dropped. Throws when every chunk fails, or
  /// [NoMatchingRecipesException] when nothing survives the check.
  Future<({List<Recipe> recipes, int rejected})> adapt(
    List<Map<String, dynamic>> raw,
    UserProfile profile,
  ) async {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(instruction(profile)),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _schema,
        temperature: 0.2,
      ),
    );

    final chunks = [
      for (var i = 0; i < raw.length; i += chunkSize) raw.sublist(i, (i + chunkSize).clamp(0, raw.length)),
    ];
    final answers = await Future.wait(chunks.map((chunk) => _ask(gemini, chunk)));

    final failures = answers.where((a) => a is! Map).toList();
    if (chunks.isNotEmpty && failures.length == chunks.length) throw failures.first;

    final recipes = <Recipe>[];
    var rejected = 0;
    for (final (index, answer) in answers.indexed) {
      if (answer is! Map<String, dynamic>) continue;
      recipes.addAll(merge(chunks[index], answer));
      rejected += (answer['rejected'] as List? ?? const []).length;
    }
    if (recipes.isEmpty) throw NoMatchingRecipesException(rejected);
    debugPrint('[RecipeAiService] kept ${recipes.length}, rejected $rejected');
    return (recipes: recipes, rejected: rejected);
  }

  /// Turns a search typed in the user's language into the English Spoonacular
  /// understands, e.g. "poulet curry" → "chicken curry". English passes
  /// through untouched.
  Future<String> toEnglish(String text, String languageCode) async {
    if (languageCode == 'en') return text;
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: model,
      generationConfig: GenerationConfig(temperature: 0),
      systemInstruction: Content.system(
        'Translate this recipe search into English, using common food words. '
        'Reply with the translation only, no quotes or punctuation.',
      ),
    );
    final response = await gemini.generateContent([Content.text(text)]);
    final english = response.text?.trim() ?? '';
    debugPrint('[RecipeAiService] search "$text" → "$english"');
    return english.isEmpty ? text : english;
  }

  /// One Gemini call. Returns the decoded answer, or the error so a single
  /// failed chunk doesn't sink the whole build.
  Future<Object> _ask(GenerativeModel gemini, List<Map<String, dynamic>> chunk) async {
    try {
      // Gemini only needs what it checks or translates.
      final input = [
        for (final r in chunk)
          {
            'id': r['id'],
            'title': r['title'],
            'readyInMinutes': r['readyInMinutes'],
            'macros': r['macros'],
            'ingredients': r['ingredients'],
            'steps': r['steps'],
            'equipment': r['equipment'],
          },
      ];
      final response = await gemini.generateContent([Content.text(jsonEncode(input))]);
      final answer = jsonDecode(response.text ?? '') as Map<String, dynamic>;
      for (final r in answer['rejected'] as List? ?? const []) {
        debugPrint('[RecipeAiService] rejected ${(r as Map)['id']}: ${r['reason']}');
      }
      return answer;
    } catch (e) {
      debugPrint('[RecipeAiService] chunk failed: $e');
      return e;
    }
  }

  /// Builds recipes from Gemini's [answer] and the matching [raw] data.
  /// Recipes Gemini did not keep are dropped, and so is any it also rejected:
  /// with allergies at stake, a contradiction counts as a rejection. Any
  /// ingredient it skipped keeps its English name.
  @visibleForTesting
  static List<Recipe> merge(List<Map<String, dynamic>> raw, Map<String, dynamic> answer) {
    final byId = {for (final r in raw) (r['id'] as num).toInt(): r};
    final rejected = {
      for (final r in (answer['rejected'] as List? ?? const []).cast<Map<String, dynamic>>())
        (r['id'] as num?)?.toInt(),
    };
    final seen = <int>{};
    return [
      for (final kept in (answer['kept'] as List? ?? const []).cast<Map<String, dynamic>>())
        if ((kept['id'] as num?)?.toInt() case final id?
            when !rejected.contains(id) && seen.add(id) && byId.containsKey(id))
          _recipe(byId[id]!, kept),
    ];
  }

  static Recipe _recipe(Map<String, dynamic> source, Map<String, dynamic> kept) {
    final adapted = {
      for (final i in (kept['ingredients'] as List? ?? const []).cast<Map<String, dynamic>>())
        (i['id'] as num?)?.toInt(): i,
    };
    final steps = (kept['steps'] as List? ?? const []).whereType<String>().toList();
    // Spoonacular often leaves out marinating or long roasting; Gemini's
    // reading of the steps only ever lengthens it.
    final ready = (source['readyInMinutes'] as num?)?.toInt() ?? 0;
    final estimate = (kept['minutes'] as num?)?.toInt() ?? 0;
    final minutes = '${estimate > ready ? estimate : ready}m';
    final title = kept['title'] as String? ?? '';
    return Recipe(
      id: '${source['id']}',
      title: title.isEmpty ? source['title'] as String? ?? '' : title,
      photoUrl: source['image'] as String? ?? '',
      macros: Macros.fromMap(Map<String, dynamic>.from(source['macros'] as Map? ?? const {})),
      time: minutes,
      cookTime: minutes,
      price: (source['price'] as num?)?.toDouble() ?? 0,
      craving: Craving.values.firstWhere((c) => c.id == kept['craving'], orElse: () => Craving.quick),
      protein: RecipeProtein.fromId(kept['protein'] as String?),
      cuisine: Cuisine.fromId(kept['cuisine'] as String?),
      creator: source['sourceName'] as String?,
      ingredients: [
        for (final i in (source['ingredients'] as List? ?? const []).cast<Map<String, dynamic>>())
          () {
            final id = (i['id'] as num?)?.toInt() ?? 0;
            final match = adapted[id];
            return Ingredient(
              id: id,
              icon: match?['icon'] as String? ?? '🍽️',
              name: match?['name'] as String? ?? i['name'] as String? ?? '',
              amount: (i['amount'] as num?)?.toDouble() ?? 0,
              unit: IngredientUnit.fromId(match?['unit'] as String? ?? i['unit'] as String?),
              aisle: Aisle.fromId(match?['aisle'] as String?),
            );
          }(),
      ],
      steps: steps.isEmpty ? (source['steps'] as List? ?? const []).whereType<String>().toList() : steps,
    );
  }

  /// How Gemini sorts an ingredient into an aisle; shared with the shopping
  /// list so both agree.
  static const aisleGuide = '''produce (fresh fruit, vegetables, fresh herbs), meat_fish,
  pasta_rice (pasta, rice, noodles, grains), tins_sauces (tins, jars, sauces,
  condiments, stock), herbs_grocery (spices, dried herbs, oils, dairy, eggs,
  baking, anything else).''';

  /// What each allergy rules out, beyond the obvious, for the allergy rule.
  static const _allergyExamples = {
    Allergy.glutenFree: 'wheat, flour, bread, pasta, couscous, soy sauce and beer',
    Allergy.lactoseFree: 'milk, butter, cream, cheese and yoghurt',
    Allergy.nutFree: 'peanuts, tree nuts, nut butters and pesto',
    Allergy.eggFree: 'eggs, mayonnaise and fresh egg pasta',
    Allergy.shellfishFree: 'prawns, crab, lobster, mussels, clams and scallops',
    Allergy.sesameFree: 'sesame seeds, sesame oil and tahini',
    Allergy.soyFree: 'soy sauce, tofu, edamame and miso',
  };

  /// The rules Gemini applies, filled in with the user's constraints.
  @visibleForTesting
  static String instruction(UserProfile profile) {
    String ids(Iterable<String> values) {
      final list = values.where((v) => v != OptionIds.none).toList();
      return list.isEmpty ? 'none' : list.join(', ');
    }

    final language = profile.languageCode == 'en' ? 'English' : 'French';
    // No meat ticked or every meat ticked means no preference, so the rule is
    // left out; "no_meat" means none at all. Meat-free dishes always pass it.
    final noMeat = profile.proteins.contains(Protein.noMeat);
    final anyMeat = !noMeat && (profile.proteins.isEmpty || profile.proteins.containsAll(Protein.meats));
    final protein = anyMeat
        ? ''
        : '''- Its main protein is a meat or fish the user did not pick. Allowed:
  ${noMeat ? 'none: the user eats no meat or fish at all' : ids(profile.proteins.map((p) => p.id))}.
  Meat-free dishes (vegetarian, vegan, tofu, meat substitutes) are always
  allowed unless a diet rules them out.
''';
    // The optional rules below end in a newline, so a skipped one leaves no
    // gap. Appliances are listed by what is missing: the model reads a short
    // "does not have" list far more reliably than the full kitchen.
    final missing = Appliance.values.where((a) => !profile.appliances.contains(a)).map((a) => a.id);
    final equipment = profile.appliances.isEmpty
        ? '''- It needs cooking or any appliance: the user has
  no cooking appliance at all, so keep only recipes that need no cooking.
'''
        : missing.isEmpty
            ? ''
            : '''- It cannot be made without an appliance the user does NOT have:
  ${missing.join(', ')}.
  (hob = stovetop, mixer = blender or food processor, slow_cooker = crockpot,
  pressure_cooker = pressure cooker or Instant Pot, barbecue = outdoor grill.)
  Every other appliance, and basic tools like pots, pans, baking dishes and
  knives, is available.
''';
    // No limit means time is never a reason to reject.
    // A rule left in with "none" still primes the model (halal's "no alcohol"
    // got applied with no diet), so diets and allergies only appear when set.
    final diets = profile.diets.where((d) => d != Diet.none);
    final halal = diets.contains(Diet.halal);
    final diet = diets.isEmpty
        ? ''
        : '''- It breaks one of the user's diets: ${ids(diets.map((d) => d.id))}.
${halal ? '  Halal means no pork and no alcohol.\n' : ''}''';
    final allergies = profile.allergies.where((a) => a != Allergy.none);
    // Examples only for the allergies picked: one for an allergy the user
    // doesn't have gets applied anyway.
    final watchFor = [for (final a in allergies) '${a.id} excludes ${_allergyExamples[a]}'];
    final allergy = allergies.isEmpty
        ? ''
        : '''- It contains something the user must avoid: ${ids(allergies.map((a) => a.id))}.
  Check every ingredient, including stocks, sauces, pastes and garnishes
  (${watchFor.join('; ')}).
''';
    final custom = profile.customInstructions.isEmpty
        ? ''
        : '''- It clearly goes against the user's own instructions: "${profile.customInstructions}"
''';
    final time = profile.hasCookLimit
        ? '''- It takes clearly longer than ${profile.cookMinutes} minutes in total, counting
  marinating, resting, simmering and roasting.
'''
        : '';
    return '''
You adapt recipes for Tably, a weekly dinner-planning app. The input is a JSON
array of recipes. Put every input recipe in exactly one of "kept" or
"rejected", by its id.

1. CHECK. Reject a recipe, with a short reason, if ANY of these is true:
$diet$allergy$protein$equipment- It is not a proper savoury main course: desserts, drinks, sauces, sides,
  snacks, or text that is not really a recipe.
$time${custom}Never reject for any other reason${halal ? '' : ': alcohol, wine and spirits are fine'}.
When unsure about a diet or an allergen, reject.

2. ADAPT every kept recipe, writing all text in $language:
- title: short and appetising, at most 60 characters.
- minutes: the realistic total time from the steps, including marinating,
  resting, simmering and roasting; readyInMinutes when that is plausible.
- steps: translate each step faithfully and concisely. Keep quantities and
  temperatures; give temperatures in °C.
- ingredients: one entry per input ingredient, same id.
  name: the ingredient in $language, lower case unless a proper noun.
  unit: the closest code for the input unit, never changing the amount. Keep
  g, kg, ml and l; Tbsp is tbsp and tsp is tsp. Plain counts, sizes (large,
  medium) and servings are piece; use to_taste when the amount is 0.
  icon: one emoji for the ingredient.
  aisle: $aisleGuide
- craving: the best fit among quick (25 minutes or less), high_protein (30 g
  protein or more), low_calorie (450 kcal or less), family_favourites,
  healthy_comfort, fakeaway (takeaway-style), easy_digestion, indulgent.
- protein: the main protein: beef, pork, chicken, fish (includes seafood),
  tofu, or vegetarian for anything else meat-free.
- cuisine: italian, asian, mexican, indian, mediterranean, or none.
''';
  }

  static final _schema = Schema.object(
    properties: {
      'kept': Schema.array(
        items: Schema.object(
          properties: {
            'id': Schema.integer(),
            'title': Schema.string(),
            'minutes': Schema.integer(),
            'craving': Schema.enumString(enumValues: [for (final c in Craving.values) c.id]),
            'protein': Schema.enumString(enumValues: [for (final p in RecipeProtein.values) p.id]),
            'cuisine': Schema.enumString(enumValues: [for (final c in Cuisine.values) c.id, 'none']),
            'ingredients': Schema.array(
              items: Schema.object(
                properties: {
                  'id': Schema.integer(),
                  'name': Schema.string(),
                  'unit': Schema.enumString(enumValues: [for (final u in IngredientUnit.values) u.id]),
                  'icon': Schema.string(),
                  'aisle': Schema.enumString(enumValues: [for (final a in Aisle.values) a.id]),
                },
              ),
            ),
            'steps': Schema.array(items: Schema.string()),
          },
        ),
      ),
      'rejected': Schema.array(
        items: Schema.object(
          properties: {
            'id': Schema.integer(),
            'reason': Schema.string(),
          },
        ),
      ),
    },
  );
}
