import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/model/preference_option.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_ai_service.dart';
import 'chat_tool.dart';
import 'chat_tools.dart';
import 'tool_payloads.dart';

/// Spoonacular, through the `spoonacular` Cloud Function. Each request spends
/// one of the user's daily searches, so none runs once they are gone, and
/// the prompt has the model look in their own recipes first.
List<ChatTool> spoonacularTools(ChatTools t) {
  /// Queries one search_recipes call may run, each spending one search.
  const maxQueries = 3;

  /// Has Gemini check found recipes against the user's rules and translate
  /// them, as for the catalogue, then keeps them for later calls.
  Future<ToolResult> found(
    List<Map<String, dynamic>> raw,
    ToolContext context, {
    Map<String, Object?> extra = const {},
  }) async {
    var recipes = const <Recipe>[];
    var rejected = 0;
    if (raw.isNotEmpty) {
      try {
        (:recipes, :rejected) = await t.ai.adapt(raw, t.profile.state.profile);
      } on NoMatchingRecipesException catch (e) {
        rejected = e.rejected;
      }
    }
    context.remember(recipes);
    return ToolResult({
      'recipes': [for (final r in recipes) ToolPayloads.recipeSummary(r, t.store)],
      if (rejected > 0) 'rejected_for_breaking_user_rules': rejected,
      ...extra,
    });
  }

  return [
    ChatTool(
      kind: ToolKind.quota,
      declaration: FunctionDeclaration(
        'search_recipes',
        "Searches Spoonacular for new main courses that respect the user's rules, about 8 per query. Spends "
            'one search per query: use it only when find_recipes has not enough fitting recipes. For several '
            'kinds of dish, give them all as queries of this one call. include_ingredients finds recipes '
            'using what the user has.',
        parameters: {
          'queries': Schema.array(
            items: Schema.string(),
            description: 'Up to $maxQueries, in English, e.g. ["chicken curry", "lemon chicken"].',
          ),
          'include_ingredients': Schema.array(items: Schema.string(), description: 'In English, e.g. ["leek", "egg"].'),
          'cuisine': Schema.enumString(enumValues: [for (final c in Cuisine.values) c.id]),
          'craving': Schema.enumString(enumValues: ['quick', 'high_protein', 'low_calorie']),
          'protein': Schema.enumString(enumValues: [for (final p in RecipeProtein.values) p.id]),
        },
        optionalParameters: ['queries', 'include_ingredients', 'cuisine', 'craving', 'protein'],
      ),
      run: (args, context) async {
        t.quota.ensureAvailable();
        final cuisine = Cuisine.fromId(args.string('cuisine'));
        // Spoonacular only reads English, and the model often writes in the
        // user's language, so both are translated (English passes as is).
        final language = t.profile.state.profile.languageCode;
        final (queries, include) = await (
          Future.wait([
            for (final q in (args.strings('queries') ?? const []).take(maxQueries)) t.ai.toEnglish(q, language),
          ]),
          Future.wait([for (final i in args.strings('include_ingredients') ?? const []) t.ai.toEnglish(i, language)]),
        ).wait;
        // One search per query; a quota running out midway keeps what was found.
        final raw = <Map<String, dynamic>>[];
        var searched = 0;
        for (final query in queries.isEmpty ? const <String?>[null] : queries) {
          if (searched > 0 && t.quota.state.remaining == 0) break;
          try {
            raw.addAll(
              await t.search.agentSearch(
                t.profile.state.profile,
                query: query,
                includeIngredients: include,
                cuisines: {?cuisine},
                craving: Craving.values.where((c) => c.id == args['craving']).firstOrNull,
                protein: args['protein'] == null ? null : RecipeProtein.fromId(args.string('protein')),
              ),
            );
          } catch (e) {
            if (searched == 0 || ChatTools.reasonFor(e) != 'quota_exhausted') rethrow;
            break;
          }
          searched++;
        }
        final seen = <Object?>{};
        return found(
          [
            for (final r in raw)
              if (seen.add(r['id'])) r,
          ],
          context,
          extra: {if (searched < queries.length) 'quota_exhausted_after': searched},
        );
      },
    ),
    ChatTool(
      kind: ToolKind.quota,
      declaration: FunctionDeclaration(
        'similar_recipes',
        'Finds recipes similar to one from Spoonacular (not a custom recipe). Spends quota.',
        parameters: {'recipe_id': Schema.string()},
      ),
      run: (args, context) async {
        t.quota.ensureAvailable();
        final id = int.tryParse(args.string('recipe_id') ?? '');
        if (id == null || id <= 0) return const ToolResult({'error': 'not_a_spoonacular_recipe'});
        return found(await t.search.similar(id), context);
      },
    ),
    ChatTool(
      kind: ToolKind.quota,
      declaration: FunctionDeclaration(
        'import_recipe_from_url',
        'Reads the recipe on a web page the user gives, checks it against their rules and translates it, so '
            'it can be shown and put in their week. Spends quota.',
        parameters: {'url': Schema.string(description: 'The full https:// address.')},
      ),
      run: (args, context) async {
        t.quota.ensureAvailable();
        final url = args.string('url');
        if (url == null || Uri.tryParse(url)?.hasScheme != true) return const ToolResult({'error': 'invalid_url'});
        final raw = await t.search.extract(url);
        if (raw.isEmpty) return const ToolResult({'error': 'no_recipe_on_page'});
        return found(raw, context);
      },
    ),
    ChatTool(
      kind: ToolKind.quota,
      declaration: FunctionDeclaration(
        'ingredient_substitutes',
        "Spoonacular's substitutes for an ingredient. Spends quota: for common swaps, answer from your own "
            'knowledge instead.',
        parameters: {'ingredient': Schema.string(description: 'In English, e.g. "butter".')},
      ),
      run: (args, context) async {
        t.quota.ensureAvailable();
        final ingredient = args.string('ingredient');
        if (ingredient == null) return const ToolResult({'error': 'missing_ingredient'});
        return ToolResult(await t.search.substitutes(ingredient));
      },
    ),
    ChatTool(
      kind: ToolKind.quota,
      declaration: FunctionDeclaration(
        'wine_pairing',
        'Wines that go with a dish or ingredient, with a short explanation. Spends quota. Never suggest wine '
            'when a diet rules out alcohol.',
        parameters: {
          'food': Schema.string(description: 'In English, e.g. "steak" or "salmon".'),
          'max_price_usd': Schema.number(),
        },
        optionalParameters: ['max_price_usd'],
      ),
      run: (args, context) async {
        t.quota.ensureAvailable();
        final food = args.string('food');
        if (food == null) return const ToolResult({'error': 'missing_food'});
        return ToolResult(await t.search.winePairing(food, maxPrice: args.number('max_price_usd')));
      },
    ),
  ];
}
