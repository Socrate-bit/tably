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

/// Thrown when Gemini won't write a recipe because the request breaks one of
/// the user's rules. [reason] is in the user's language.
class RecipeRefusedException implements Exception {
  const RecipeRefusedException(this.reason);

  final String reason;

  @override
  String toString() => 'RecipeRefusedException($reason)';
}

/// Checks Spoonacular candidates against the user's constraints and adapts
/// the survivors with Gemini: translation, craving, protein, cuisine, emoji,
/// unit and aisle. Numbers, photos and sources always come from Spoonacular.
class RecipeAiService {
  static const model = 'gemini-3.1-flash-lite';

  /// Writing a whole recipe that respects every rule takes more judgement
  /// than the lite model has, so it uses the stronger one.
  static const writerModel = 'gemini-3.5-flash';

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

  /// Writes a whole recipe for [request], or with [base] a copy of it
  /// changed only as asked ("olive oil instead of butter"). The result is a
  /// custom recipe the user owns, with a fresh id. Throws
  /// [RecipeRefusedException] when the request breaks the user's rules.
  Future<Recipe> write(String request, UserProfile profile, {Recipe? base}) async {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: writerModel,
      systemInstruction: Content.system(writerInstruction(profile, derived: base != null)),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _writerSchema,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      ),
    );
    final input = {'request': request, if (base != null) 'base': {'id': base.id, ...base.toMap()}};
    final response = await gemini.generateContent([Content.text(jsonEncode(input))]);
    final answer = jsonDecode(response.text ?? '') as Map<String, dynamic>;
    final recipe = written(answer, id: 'custom_${DateTime.now().microsecondsSinceEpoch}', base: base);
    debugPrint('[RecipeAiService] wrote "${recipe.title}"${base == null ? '' : ' from ${base.id}'}');
    return recipe;
  }

  /// Builds the custom recipe Gemini wrote in [answer]. A derived recipe
  /// keeps the [base]'s photo and credit, and its ingredient ids where Gemini
  /// kept the line, so the shopping list still merges them.
  @visibleForTesting
  static Recipe written(Map<String, dynamic> answer, {required String id, Recipe? base}) {
    final refused = (answer['refused'] as String? ?? '').trim();
    if (refused.isNotEmpty) throw RecipeRefusedException(refused);
    final baseIds = {for (final i in base?.ingredients ?? const <Ingredient>[]) i.id};
    final minutes = '${(answer['minutes'] as num?)?.toInt() ?? 0}m';
    return Recipe(
      id: id,
      title: (answer['title'] as String? ?? '').trim(),
      photoUrl: base?.photoUrl ?? '',
      macros: Macros.fromMap(Map<String, dynamic>.from(answer['macros'] as Map? ?? const {})),
      time: minutes,
      cookTime: minutes,
      price: (answer['price'] as num?)?.toDouble() ?? base?.price ?? 0,
      craving: Craving.values.firstWhere((c) => c.id == answer['craving'], orElse: () => Craving.quick),
      protein: RecipeProtein.fromId(answer['protein'] as String?),
      cuisine: Cuisine.fromId(answer['cuisine'] as String?),
      creator: base?.creator,
      ingredients: [
        for (final i in (answer['ingredients'] as List? ?? const []).cast<Map<String, dynamic>>())
          Ingredient(
            id: baseIds.contains((i['base_id'] as num?)?.toInt()) ? (i['base_id'] as num).toInt() : 0,
            icon: i['icon'] as String? ?? '🍽️',
            name: i['name'] as String? ?? '',
            amount: (i['amount'] as num?)?.toDouble() ?? 0,
            unit: IngredientUnit.fromId(i['unit'] as String?),
            aisle: Aisle.fromId(i['aisle'] as String?),
          ),
      ],
      steps: (answer['steps'] as List? ?? const []).whereType<String>().toList(),
      origin: RecipeOrigin.chef,
    );
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
    final minutes = '${(source['readyInMinutes'] as num?)?.toInt() ?? 0}m';
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

  /// The rules Gemini applies, filled in with the user's constraints.
  @visibleForTesting
  static String instruction(UserProfile profile) {
    final c = _constraints(profile);
    final language = _language(profile);
    return '''
You adapt recipes for Tably, a weekly dinner-planning app. The input is a JSON
array of recipes. Put every input recipe in exactly one of "kept" or
"rejected", by its id.

1. CHECK. Reject a recipe, with a short reason, if ANY of these is true:
- It breaks one of the user's diets: ${c.diets}.
  Halal means no pork and no alcohol.
- It contains something the user must avoid: ${c.allergies}.
  Check every ingredient, including stocks, sauces, pastes and garnishes
  (e.g. nut_free excludes peanuts, tree nuts, nut butters and pesto;
  lactose_free excludes milk, butter, cream and cheese).
- Its main protein is a meat or fish the user did not pick. Allowed:
  ${c.proteins}. Vegetarian and tofu dishes are always allowed unless a diet
  rules them out.
- It needs equipment the user lacks. The user has: ${c.appliances}
  (hob = stovetop, mixer = blender or food processor). Reject anything that
  must be baked or roasted in an oven when "oven" is missing, or blended when
  "mixer" is missing.
${c.custom.isEmpty ? '' : "- It breaks one of the user's own rules, which are as strict as allergies: ${c.custom}.\n"}- It is not a proper savoury main course: desserts, drinks, sauces, sides,
  snacks, or text that is not really a recipe.
- Its steps need far longer than readyInMinutes, e.g. overnight marinating or
  hours of roasting.
When unsure about a diet or an allergen, reject.

2. ADAPT every kept recipe, writing all text in $language:
- title: short and appetising, at most 60 characters.
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

  /// The rules Gemini follows to write a recipe, or with [derived] to change
  /// one, filled in with the user's constraints.
  @visibleForTesting
  static String writerInstruction(UserProfile profile, {required bool derived}) {
    final c = _constraints(profile);
    final language = _language(profile);
    final task = derived
        ? '''The input has a "base" recipe and a "request". Return a copy of the base
changed only as requested. Keep every other ingredient with its id as
base_id, its amount and its unit, and keep the steps, adjusting only what
the change affects. The title may say what changed.'''
        : '''The input has a "request". Write one savoury main course that fulfils it,
with realistic amounts and clear steps a home cook can follow.''';
    return '''
You are Tably's chef and write recipes for a weekly dinner-planning app.
$task

Every recipe MUST respect the user's constraints:
- Diets: ${c.diets}. Halal means no pork and no alcohol.
- Must avoid: ${c.allergies}, including in stocks, sauces, pastes and
  garnishes.
- Main protein allowed: ${c.proteins}. Vegetarian and tofu are always fine
  unless a diet rules them out.
- Appliances the user has: ${c.appliances} (hob = stovetop, mixer = blender
  or food processor).
${c.custom.isEmpty ? '' : "- The user's own rules, as strict as allergies: ${c.custom}.\n"}If the request cannot be met without breaking one of these, set "refused"
to a short reason in $language and leave everything else empty. Otherwise
set "refused" to an empty string.

Write all text in $language:
- title: short and appetising, at most 60 characters.
- minutes: total time from start to plate.
- price: estimated cost of one portion in euros at a French discount
  supermarket.
- macros: estimated per portion.
- ingredients: amounts for ONE portion.
  base_id: the base ingredient's id when the line comes from the base,
  else 0.
  name: lower case unless a proper noun.
  unit: g, kg, ml or l for weights and volumes; tbsp, tsp, piece, clove,
  slice, bunch, sprig, leaf, pinch, can or pack otherwise; to_taste with
  amount 0 for seasoning.
  icon: one emoji for the ingredient.
  aisle: $aisleGuide
- steps: concise, one action each, temperatures in °C.
- craving: the best fit among quick (25 minutes or less), high_protein (30 g
  protein or more), low_calorie (450 kcal or less), family_favourites,
  healthy_comfort, fakeaway (takeaway-style), easy_digestion, indulgent.
- protein: the main protein: beef, pork, chicken, fish (includes seafood),
  tofu, or vegetarian for anything else meat-free.
- cuisine: italian, asian, mexican, indian, mediterranean, or none.
''';
  }

  static String _language(UserProfile profile) => profile.languageCode == 'en' ? 'English' : 'French';

  /// The user's hard constraints, worded for a prompt.
  static ({String diets, String allergies, String proteins, String appliances, String custom}) _constraints(
    UserProfile profile,
  ) {
    String ids(Iterable<String> values) {
      final list = values.where((v) => v != OptionIds.none).toList();
      return list.isEmpty ? 'none' : list.join(', ');
    }

    return (
      diets: ids(profile.diets.map((d) => d.id)),
      allergies: ids(profile.allergies.map((a) => a.id)),
      // No meat ticked means no preference; "no_meat" means none at all.
      proteins: profile.proteins.contains(Protein.noMeat)
          ? 'none: the user eats no meat or fish at all'
          : profile.proteins.isEmpty
              ? 'any meat or fish'
              : ids(profile.proteins.map((p) => p.id)),
      // No appliance ticked means literally none: only no-cook recipes pass.
      appliances: profile.appliances.isEmpty
          ? 'no cooking appliance at all, so keep only recipes that need no cooking and no appliance'
          : ids(profile.appliances.map((a) => a.id)),
      // The user's own rules in their words; empty when there are none.
      custom: profile.customPreferences.map((p) => '"$p"').join('; '),
    );
  }

  static final _schema = Schema.object(
    properties: {
      'kept': Schema.array(
        items: Schema.object(
          properties: {
            'id': Schema.integer(),
            'title': Schema.string(),
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

  static final _writerSchema = Schema.object(
    properties: {
      'refused': Schema.string(),
      'title': Schema.string(),
      'minutes': Schema.integer(),
      'price': Schema.number(),
      'macros': Schema.object(
        properties: {
          'kcal': Schema.integer(),
          'protein': Schema.integer(),
          'carbs': Schema.integer(),
          'fat': Schema.integer(),
        },
      ),
      'craving': Schema.enumString(enumValues: [for (final c in Craving.values) c.id]),
      'protein': Schema.enumString(enumValues: [for (final p in RecipeProtein.values) p.id]),
      'cuisine': Schema.enumString(enumValues: [for (final c in Cuisine.values) c.id, 'none']),
      'ingredients': Schema.array(
        items: Schema.object(
          properties: {
            'base_id': Schema.integer(),
            'name': Schema.string(),
            'amount': Schema.number(),
            'unit': Schema.enumString(enumValues: [for (final u in IngredientUnit.values) u.id]),
            'icon': Schema.string(),
            'aisle': Schema.enumString(enumValues: [for (final a in Aisle.values) a.id]),
          },
        ),
      ),
      'steps': Schema.array(items: Schema.string()),
    },
  );
}
