import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_ai_service.dart';
import '../model/shopping_item.dart';

/// One shopping item before it gets its id and position.
typedef _Draft = ({Ingredient first, Aisle aisle, String icon, String name, double amount, IngredientUnit unit});

/// Turns the week's raw ingredient lines into a shopping list with Gemini:
/// similar ingredients merge into one item ("oignon", "oignons", "sel de
/// mer"), each in a single unit.
class ShoppingAiService {
  /// Telling which lines are the same product takes judgement the lite model
  /// lacks ("cumin moulu" is "cumin"), and this runs only when the week
  /// changes, so it uses the stronger model with a little thinking.
  static const model = 'gemini-3.5-flash';

  /// Part of every list's source: bump it when the rules change, so lists
  /// built with the old ones are rebuilt.
  static const version = 2;

  /// Builds the list for [lines], stamped with [source]. Throws when Gemini
  /// fails.
  Future<List<ShoppingItem>> aggregate(List<Ingredient> lines, String languageCode, String source) async {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(instruction(languageCode)),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _schema,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      ),
    );
    final input = [
      for (final (ref, line) in lines.indexed)
        {'ref': ref, 'name': line.name, 'amount': line.amount, 'unit': line.unit.id},
    ];
    final response = await gemini.generateContent([Content.text(jsonEncode(input))]);
    final answer = jsonDecode(response.text ?? '') as Map<String, dynamic>;
    final items = merge(lines, answer, source);
    debugPrint('[ShoppingAiService] ${lines.length} lines → ${items.length} items');
    return items;
  }

  /// Builds items from Gemini's [answer] over [lines], sorted by aisle then
  /// name. Items left apart under the same name and unit are summed. A line
  /// no item covers becomes its own item, so nothing is ever dropped; with
  /// an empty answer, that is every line, which is the fallback when Gemini
  /// fails.
  static List<ShoppingItem> merge(List<Ingredient> lines, Map<String, dynamic> answer, String source) {
    final drafts = <(String, IngredientUnit), _Draft>{};
    void add(_Draft d) => drafts.update(
      (d.name.toLowerCase(), d.unit),
      (twin) => (
        first: twin.first,
        aisle: twin.aisle,
        icon: twin.icon,
        name: twin.name,
        amount: twin.amount + d.amount,
        unit: twin.unit,
      ),
      ifAbsent: () => d,
    );

    final covered = <int>{};
    for (final item in (answer['items'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final refs = [
        for (final r in item['refs'] as List? ?? const [])
          if ((r as num).toInt() case final ref when ref >= 0 && ref < lines.length) ref,
      ]..sort();
      final name = (item['name'] as String? ?? '').trim();
      if (refs.isEmpty || name.isEmpty) continue;
      covered.addAll(refs);
      add((
        first: lines[refs.first],
        aisle: Aisle.fromId(item['aisle'] as String?),
        icon: item['icon'] as String? ?? lines[refs.first].icon,
        name: name,
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        unit: IngredientUnit.fromId(item['unit'] as String?),
      ));
    }
    for (final (ref, line) in lines.indexed) {
      if (covered.contains(ref)) continue;
      add((first: line, aisle: line.aisle, icon: line.icon, name: line.name, amount: line.amount, unit: line.unit));
    }

    final sorted = drafts.values.toList()
      ..sort((a, b) {
        final byAisle = a.aisle.index.compareTo(b.aisle.index);
        return byAisle != 0 ? byAisle : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final ids = <String>{};
    return [
      for (final (index, d) in sorted.indexed)
        ShoppingItem(
          id: _uniqueId(ids, d.first, d.name),
          aisle: d.aisle,
          icon: d.icon,
          name: d.name,
          amount: d.amount,
          unit: d.unit,
          source: source,
          order: index,
        ),
    ];
  }

  /// A stable document id from the item's first ingredient: Spoonacular's id
  /// when there is one, else its name. A line split into several items
  /// ("salt and pepper") adds the item's name to stay unique. Anything but
  /// letters and digits becomes "_", so an id never forms a path.
  static String _uniqueId(Set<String> taken, Ingredient first, String name) {
    String slug(String text) => text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final base = first.id > 0 ? '${first.id}' : 'name_${slug(first.name)}';
    var id = base;
    if (!taken.add(id)) {
      id = '${base}_${slug(name)}';
      for (var n = 2; !taken.add(id); n++) {
        id = '${base}_${slug(name)}_$n';
      }
    }
    return id;
  }

  /// The rules Gemini applies to the lines.
  @visibleForTesting
  static String instruction(String languageCode) {
    final language = languageCode == 'en' ? 'English' : 'French';
    return '''
You write the weekly shopping list for Tably, a dinner-planning app. The input
is a JSON array of ingredient lines {ref, name, amount, unit}. Amounts are
already the totals for the whole week.

Return one item per product a shopper picks off the shelf:
- Merge every line that is the same product, whatever its wording: singular
  and plural, size, colour, variety, and any preparation or cooking state
  (ground, hard-boiled, chopped, minced, sliced, grated, beaten, cooked,
  melted, softened, at room temperature). For example: cumin and ground
  cumin are one item, cumin; egg, eggs and hard-boiled egg are one item,
  egg; onion and onions are one item, onion; salt, sea salt and kosher salt
  are one item, salt. When unsure whether two lines are the same product,
  merge them.
- Split a line that names several products ("salt and pepper") into one item
  each, both listing that line's ref.
- refs: every input ref the item covers. Every input ref must appear in at
  least one item.
- amount and unit: ONE total in ONE unit, converting every line the item
  covers (1 tbsp = 15 ml, 1 tsp = 5 ml, 1 kg = 1000 g, and typical weights
  for counted things, e.g. a medium onion is about 150 g). Use the unit the
  product is bought in: piece for things bought whole (onions, eggs, lemons,
  garlic bulbs), g for meat, fish, cheese, pasta, rice and loose produce, ml
  for liquids, tsp, tbsp or pinch for small amounts of spices and seasonings.
  Round up to a practical amount. When no line gives an amount, use
  to_taste with amount 0.
- name: the product in $language, lower case, short and generic, with no
  preparation or variety (e.g. "sel", not "sel de mer fin"; "cumin", not
  "cumin moulu"; "œuf", not "œuf dur"). Two items never share a name.
- icon: one emoji for the product.
- aisle: ${RecipeAiService.aisleGuide}
''';
  }

  static final _schema = Schema.object(
    properties: {
      'items': Schema.array(
        items: Schema.object(
          properties: {
            'refs': Schema.array(items: Schema.integer()),
            'name': Schema.string(),
            'icon': Schema.string(),
            'aisle': Schema.enumString(enumValues: [for (final a in Aisle.values) a.id]),
            'amount': Schema.number(),
            'unit': Schema.enumString(enumValues: [for (final u in IngredientUnit.values) u.id]),
          },
          // The product's name comes first, so the lines it covers follow from it.
          propertyOrdering: ['name', 'refs', 'unit', 'amount', 'icon', 'aisle'],
        ),
      ),
    },
  );
}
