import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_ai_service.dart';
import 'chat_tool.dart';
import 'chat_tools.dart';
import 'tool_payloads.dart';

/// Finding, showing, rating and writing recipes.
List<ChatTool> recipeTools(ChatTools t) {
  ToolResult unknownRecipe(String? id) => ToolResult({'error': 'unknown_recipe_id', 'recipe_id': id});

  return [
    ChatTool(
      kind: ToolKind.read,
      declaration: FunctionDeclaration(
        'get_recipe',
        'A recipe in full: ingredients for one portion, steps, macros and price, plus what the user did with '
            'it (favourite, cooked, rating, note) and the meals it fills this week.',
        parameters: {'recipe_id': Schema.string()},
      ),
      run: (args, context) async {
        final id = args.string('recipe_id');
        final recipe = id == null ? null : context.recipe(id);
        if (recipe == null) return unknownRecipe(id);
        final interaction = t.recipes.state.interactionFor(recipe.id);
        return ToolResult({
          ...ToolPayloads.recipeDetail(recipe, t.store),
          'favourite': interaction.favourite,
          'cooked': interaction.cooked,
          'rating': interaction.rating,
          if (interaction.note.isNotEmpty) 'note': interaction.note,
          'in_week': [
            for (final s in t.plan.state.week.slots)
              if (s.recipe.id == recipe.id) s.key,
          ],
        });
      },
    ),
    ChatTool(
      kind: ToolKind.read,
      declaration: FunctionDeclaration(
        'find_recipes',
        "Searches the user's own recipes (their pool and favourites) without spending any Spoonacular quota. "
            'Always try this before search_recipes.',
        parameters: {
          'query': Schema.string(description: 'Words to find in the title or ingredients, in the user\'s language.'),
          'craving': Schema.enumString(enumValues: [for (final c in Craving.values) c.id]),
          'protein': Schema.enumString(enumValues: [for (final p in RecipeProtein.values) p.id]),
          'cuisine': Schema.enumString(enumValues: [for (final c in Cuisine.values) c.id]),
          'max_minutes': Schema.integer(),
          'max_price_eur': Schema.number(description: 'Per portion, at the user\'s store.'),
          'favourites_only': Schema.boolean(),
        },
        optionalParameters: [
          'query',
          'craving',
          'protein',
          'cuisine',
          'max_minutes',
          'max_price_eur',
          'favourites_only',
        ],
      ),
      run: (args, context) async {
        final query = args.string('query')?.toLowerCase();
        final maxMinutes = args.integer('max_minutes');
        final maxPrice = args.number('max_price_eur');
        final favourites = t.recipes.state.favouritesIn(t.catalogue.state.recipes);
        final pool = args.boolean('favourites_only') == true
            ? favourites
            : {
                for (final r in [...t.catalogue.state.recipes, ...favourites]) r.id: r,
              }.values;
        final matches = [
          for (final r in pool)
            if ((query == null ||
                    r.title.toLowerCase().contains(query) ||
                    r.ingredients.any((i) => i.name.toLowerCase().contains(query))) &&
                (args['craving'] == null || r.craving.id == args['craving']) &&
                (args['protein'] == null || r.protein.id == args['protein']) &&
                (args['cuisine'] == null || r.cuisine?.id == args['cuisine']) &&
                (maxMinutes == null || ToolPayloads.minutes(r) <= maxMinutes) &&
                (maxPrice == null || r.price * t.store.priceFactor <= maxPrice))
              r,
        ];
        return ToolResult({
          'total': matches.length,
          'recipes': [for (final r in matches.take(15)) ToolPayloads.recipeSummary(r, t.store)],
        });
      },
    ),
    ChatTool(
      kind: ToolKind.read,
      declaration: NoArgsDeclaration(
        'get_recipe_history',
        "The user's favourites, recently opened recipes, the ones they cooked, their ratings and notes.",
      ),
      run: (args, context) async {
        final state = t.recipes.state;
        final catalogue = t.catalogue.state.recipes;
        String? title(String id) => context.recipe(id)?.title;
        return ToolResult({
          'favourites': [
            for (final r in state.favouritesIn(catalogue).take(20)) {'id': r.id, 'title': r.title},
          ],
          'recently_viewed': [
            for (final r in state.recentlyViewedIn(catalogue)) {'id': r.id, 'title': r.title},
          ],
          'cooked': [
            for (final i in state.interactions.values)
              if (i.cooked) {'id': i.recipeId, 'title': title(i.recipeId)},
          ],
          'rated': [
            for (final i in state.interactions.values)
              if (i.rating > 0) {'id': i.recipeId, 'title': title(i.recipeId), 'rating': i.rating},
          ],
          'notes': [
            for (final i in state.interactions.values)
              if (i.note.isNotEmpty) {'id': i.recipeId, 'title': title(i.recipeId), 'note': i.note},
          ],
        });
      },
    ),
    ChatTool(
      kind: ToolKind.read,
      declaration: FunctionDeclaration(
        'show_recipes',
        'Shows recipes as cards under your reply, which the user can open, save or put in their week. Use it '
            'whenever you suggest recipes, and keep your text short.',
        parameters: {'recipe_ids': Schema.array(items: Schema.string(), description: 'Up to 6.')},
      ),
      run: (args, context) async {
        final ids = (args.strings('recipe_ids') ?? const []).take(6).toList();
        final found = [for (final id in ids) ?context.recipe(id)];
        context.show(found);
        return ToolResult({
          'shown': found.length,
          'unknown_ids': [
            for (final id in ids)
              if (context.recipe(id) == null) id,
          ],
        });
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'update_recipe',
        'Saves or unsaves a recipe as a favourite, marks it cooked or not, rates it (1-5, 0 clears) or sets '
            'its note. Give only what changes.',
        parameters: {
          'recipe_id': Schema.string(),
          'favourite': Schema.boolean(),
          'cooked': Schema.boolean(),
          'rating': Schema.integer(description: '1-5, or 0 to clear.'),
          'note': Schema.string(),
        },
        optionalParameters: ['favourite', 'cooked', 'rating', 'note'],
      ),
      run: (args, context) async {
        final id = args.string('recipe_id');
        final recipe = id == null ? null : context.recipe(id);
        if (recipe == null) return unknownRecipe(id);
        final current = t.recipes.state.interactionFor(recipe.id);
        final favourite = args.boolean('favourite');
        final cooked = args.boolean('cooked');
        final rating = args.integer('rating')?.clamp(0, 5);
        final note = args['note'] as String?;
        final changes = <String, Object?>{
          if (favourite != null && favourite != current.favourite) 'favourite': favourite,
          if (cooked != null && cooked != current.cooked) 'cooked': cooked,
          if (rating != null && rating != current.rating) 'rating': rating,
          if (note != null && note.trim() != current.note) 'note': note.trim(),
        };
        if (changes.isEmpty) return const ToolResult({'unchanged': true});
        return ToolProposal(
          preview: {'title': recipe.title, ...changes},
          commit: () async {
            if (changes.containsKey('favourite')) await t.recipes.toggleFavourite(recipe);
            if (changes.containsKey('cooked')) await t.recipes.toggleCooked(recipe.id);
            if (changes['rating'] case final int r) await t.recipes.setRating(recipe.id, r);
            if (changes['note'] case final String n) await t.recipes.setNote(recipe.id, n);
            return {'ok': true};
          },
        );
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'create_custom_recipe',
        "Writes a brand-new recipe for the user from a description (e.g. \"a quick creamy leek pasta\"), "
            "respecting all their rules, and adds it to their recipes once they approve; with slot_key it also "
            'goes in that meal. Use it when nothing in their recipes or on Spoonacular fits.',
        parameters: {
          'request': Schema.string(description: 'What to cook, with every detail the user gave.'),
          'slot_key': Schema.string(description: 'A meal of the week to put it in.'),
        },
        optionalParameters: ['slot_key'],
      ),
      run: (args, context) async {
        final request = args.string('request');
        if (request == null) return const ToolResult({'error': 'missing_request'});
        final key = args.string('slot_key');
        final slot = key == null ? null : t.plan.state.week.slotByKey(key);
        if (key != null && slot == null) return ToolResult({'error': 'unknown_slot_key', 'slot_key': key});
        final Recipe draft;
        try {
          draft = await t.ai.write(request, t.profile.state.profile);
        } on RecipeRefusedException catch (e) {
          return ToolResult({'refused': e.reason});
        }
        context.remember([draft]);
        return ToolProposal(
          preview: {'title': draft.title, if (slot != null) 'slot_key': slot.key, if (slot != null) 'day': slot.day.id},
          recipes: [draft],
          commit: () async {
            await t.catalogue.addRecipe(draft);
            if (slot != null) await t.plan.replace(slot.key, draft);
            unawaited(t.analytics.capture(AnalyticsEvents.customRecipeCreated, properties: {'derived': false}));
            return {'ok': true, 'recipe': ToolPayloads.recipeSummary(draft, t.store)};
          },
        );
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'derive_recipe',
        'Makes the user\'s own version of an existing recipe with a change, e.g. "olive oil instead of butter", '
            '"no onion", "for an air fryer" or "more protein". The original stays; with replace_in_week the new '
            'version takes its place in the week.',
        parameters: {
          'recipe_id': Schema.string(description: 'The recipe to start from.'),
          'changes': Schema.string(description: 'What to change, in the user\'s words.'),
          'replace_in_week': Schema.boolean(),
        },
        optionalParameters: ['replace_in_week'],
      ),
      run: (args, context) async {
        final id = args.string('recipe_id');
        final base = id == null ? null : context.recipe(id);
        if (base == null) return unknownRecipe(id);
        final changes = args.string('changes');
        if (changes == null) return const ToolResult({'error': 'missing_changes'});
        final inWeek = t.plan.state.week.slots.any((s) => !s.isLeftover && s.recipe.id == base.id);
        final replace = args.boolean('replace_in_week') == true && inWeek;
        final Recipe draft;
        try {
          draft = await t.ai.write(changes, t.profile.state.profile, base: base);
        } on RecipeRefusedException catch (e) {
          return ToolResult({'refused': e.reason});
        }
        context.remember([draft]);
        return ToolProposal(
          preview: {'title': draft.title, 'base_title': base.title, 'replace_in_week': replace},
          recipes: [draft],
          commit: () async {
            await t.catalogue.addRecipe(draft);
            if (replace) await t.plan.replaceRecipe(base.id, draft.id);
            unawaited(t.analytics.capture(AnalyticsEvents.customRecipeCreated, properties: {'derived': true}));
            return {'ok': true, 'recipe': ToolPayloads.recipeSummary(draft, t.store)};
          },
        );
      },
    ),
  ];
}
