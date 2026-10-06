import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/model/preference_option.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_ai_service.dart';
import 'chat_tool.dart';
import 'chat_tools.dart';
import 'tool_payloads.dart';

/// Spoonacular, through the `spoonacular` Cloud Function. Each call spends
/// one of the user's daily searches, so none runs once they are gone, and
/// the prompt has the model look in their own recipes first.
List<ChatTool> spoonacularTools(ChatTools t) {
  /// Has Gemini check found recipes against the user's rules and translate
  /// them, as for the catalogue, then keeps them for later calls.
  Future<ToolResult> found(List<Map<String, dynamic>> raw, ToolContext context) async {
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
    });
  }

  return [
    ChatTool(
      kind: ToolKind.quota,
      declaration: FunctionDeclaration(
        'search_recipes',
        "Searches Spoonacular for new main courses that respect the user's rules: about 24 for one search of "
            'their small daily allowance. Use it only when find_recipes has not enough fitting recipes. Keep '
            'the query broad ("chicken" rather than "chicken curry") to get varied dishes in one go. '
            'include_ingredients finds recipes using what the user has.',
        parameters: {
          'query': Schema.string(description: 'In English, e.g. "chicken" or "fish".'),
          'include_ingredients': Schema.array(items: Schema.string(), description: 'In English, e.g. ["leek", "egg"].'),
          'cuisine': Schema.enumString(enumValues: [for (final c in Cuisine.values) c.id]),
          'craving': Schema.enumString(enumValues: ['quick', 'high_protein', 'low_calorie']),
          'protein': Schema.enumString(enumValues: [for (final p in RecipeProtein.values) p.id]),
        },
        optionalParameters: ['query', 'include_ingredients', 'cuisine', 'craving', 'protein'],
      ),
      run: (args, context) async {
        t.quota.ensureAvailable();
        final cuisine = Cuisine.fromId(args.string('cuisine'));
        // Spoonacular only reads English, and the model often writes in the
        // user's language, so both are translated (English passes as is).
        final language = t.profile.state.profile.languageCode;
        final query = args.string('query');
        final (english, include) = await (
          query == null ? Future<String?>.value() : t.ai.toEnglish(query, language),
          Future.wait([for (final i in args.strings('include_ingredients') ?? const []) t.ai.toEnglish(i, language)]),
        ).wait;
        final raw = await t.search.agentSearch(
          t.profile.state.profile,
          query: english,
          includeIngredients: include,
          cuisines: {?cuisine},
          craving: Craving.values.where((c) => c.id == args['craving']).firstOrNull,
          protein: args['protein'] == null ? null : RecipeProtein.fromId(args.string('protein')),
        );
        return found(raw, context);
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
