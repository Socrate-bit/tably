import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/model/store.dart';
import '../../plan/model/week_plan.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import 'chat_tool.dart';
import 'chat_tools.dart';
import 'tool_payloads.dart';

/// Reading and changing the week.
List<ChatTool> planTools(ChatTools t) {
  ToolResult unknownSlot(String? key) => ToolResult({'error': 'unknown_slot_key', 'slot_key': key});
  ToolResult unknownRecipe(String? id) => ToolResult({'error': 'unknown_recipe_id', 'recipe_id': id});
  Map<String, Object?> slotJson(PlanSlot s) => {
    'slot_key': s.key,
    'day': s.day.id,
    'meal': s.slot.id,
    'title': s.recipe.title,
  };

  return [
    ChatTool(
      kind: ToolKind.read,
      declaration: NoArgsDeclaration(
        'get_week_plan',
        "The user's week: every meal with its slot_key, day, meal (lunch or dinner) and recipe, which "
            'meals are leftovers, the estimated total at their store, and whether their recipes are outdated '
            'after a preferences change.',
      ),
      run: (args, context) async => ToolResult(t.weekJson()),
    ),
    ChatTool(
      kind: ToolKind.read,
      declaration: NoArgsDeclaration(
        'compare_stores',
        "What the week costs at each supported supermarket, cheapest first, and the user's current store.",
      ),
      run: (args, context) async {
        final week = t.plan.state.week;
        final stores = [...Store.values]..sort((a, b) => a.priceFactor.compareTo(b.priceFactor));
        return ToolResult({
          'current_store': t.store.id,
          'stores': [
            for (final s in stores)
              {'store': s.id, 'name': s.displayName, 'total_eur': (week.totalAt(s) * 100).round() / 100},
          ],
        });
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: NoArgsDeclaration(
        'regenerate_week',
        'Fetches a new pool of recipes for the current preferences and deals a whole new week, dropping every '
            'swap and reordering. Spends one Spoonacular request and takes up to a minute. Use it when the user '
            'wants a new week, or after a preferences change made their recipes outdated.',
      ),
      run: (args, context) async => ToolProposal(
        preview: const {},
        commit: () async {
          final done = await t.plan.regenerate();
          return done
              ? {'ok': true, 'week': t.weekJson()}
              : {'error': CatalogueCubit.reasonFor(t.catalogue.state.error)};
        },
      ),
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'change_meal',
        'Puts a recipe in one meal of the week, or a random new one from the pool when recipe_id is left out. '
            "The meal's leftovers follow it. recipe_id can be any recipe the user can see, including one found "
            'or written in this chat.',
        parameters: {
          'slot_key': Schema.string(description: 'The meal to change, from get_week_plan, e.g. "tuesday|dinner".'),
          'recipe_id': Schema.string(description: 'The recipe to put there; leave out for a random one.'),
        },
        optionalParameters: ['recipe_id'],
      ),
      run: (args, context) async {
        final key = args.string('slot_key');
        final slot = key == null ? null : t.plan.state.week.slotByKey(key);
        if (slot == null) return unknownSlot(key);
        final id = args.string('recipe_id');
        final recipe = id == null ? null : context.recipe(id);
        if (id != null && recipe == null) return unknownRecipe(id);
        return ToolProposal(
          preview: {...slotJson(slot), 'to': recipe?.title},
          recipes: [?recipe],
          commit: () async {
            if (recipe == null) {
              final next = await t.plan.regenerateMeal(slot);
              if (next == null) return {'error': 'no_other_recipe_in_pool'};
              return {'ok': true, 'new_recipe': ToolPayloads.recipeSummary(next.recipe, t.store)};
            }
            await t.ensureInPool(recipe);
            await t.plan.replace(slot.key, recipe);
            return {'ok': true, 'week': t.weekJson()};
          },
        );
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'replace_recipe_everywhere',
        'Replaces a recipe wherever it is cooked this week with another one; its leftovers follow.',
        parameters: {
          'old_recipe_id': Schema.string(description: 'A recipe currently in the week.'),
          'new_recipe_id': Schema.string(description: 'The recipe to cook instead.'),
        },
      ),
      run: (args, context) async {
        final oldId = args.string('old_recipe_id');
        final cooked = t.plan.state.week.slots.where((s) => !s.isLeftover && s.recipe.id == oldId).toList();
        if (cooked.isEmpty) return ToolResult({'error': 'recipe_not_in_week', 'recipe_id': oldId});
        final newId = args.string('new_recipe_id');
        final recipe = newId == null ? null : context.recipe(newId);
        if (recipe == null) return unknownRecipe(newId);
        return ToolProposal(
          preview: {'from': cooked.first.recipe.title, 'to': recipe.title, 'meals': cooked.length},
          recipes: [recipe],
          commit: () async {
            await t.ensureInPool(recipe);
            await t.plan.replaceRecipe(cooked.first.recipe.id, recipe.id);
            return {'ok': true, 'week': t.weekJson()};
          },
        );
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: FunctionDeclaration(
        'swap_meals',
        'Swaps the places of two meals in the week, e.g. to eat Friday\'s dinner on Monday. Leftovers follow: '
            'each dish is cooked at its first meal.',
        parameters: {
          'slot_a': Schema.string(description: 'slot_key of the first meal.'),
          'slot_b': Schema.string(description: 'slot_key of the second meal.'),
        },
      ),
      run: (args, context) async {
        final week = t.plan.state.week;
        final a = week.slotByKey(args.string('slot_a') ?? '');
        final b = week.slotByKey(args.string('slot_b') ?? '');
        if (a == null) return unknownSlot(args.string('slot_a'));
        if (b == null || b.key == a.key) return unknownSlot(args.string('slot_b'));
        return ToolProposal(
          preview: {'a': slotJson(a), 'b': slotJson(b)},
          commit: () async {
            final keys = [for (final s in t.plan.state.week.slots) s.key];
            final i = keys.indexOf(a.key), j = keys.indexOf(b.key);
            if (i < 0 || j < 0) return {'error': 'week_changed'};
            keys[i] = b.key;
            keys[j] = a.key;
            await t.plan.reorder(keys);
            return {'ok': true, 'week': t.weekJson()};
          },
        );
      },
    ),
    ChatTool(
      kind: ToolKind.write,
      declaration: NoArgsDeclaration(
        'keep_current_recipes',
        "Keeps the user's current recipes after a preferences change made them outdated, instead of "
            'regenerating the week.',
      ),
      run: (args, context) async {
        if (!t.catalogue.state.outdated) return const ToolResult({'error': 'recipes_not_outdated'});
        return ToolProposal(
          preview: const {},
          commit: () async {
            await t.catalogue.keep();
            return {'ok': true};
          },
        );
      },
    ),
  ];
}
