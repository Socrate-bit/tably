import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_ai_service.dart';
import '../model/shopping_item.dart';

/// Turns the week's raw ingredient lines into a shopping list with Gemini:
/// similar ingredients merge into one item ("oignon", "oignons", "sel de
/// mer"), each in a single unit.
class ShoppingAiService {
  /// Builds the list for [lines], stamped with [source]. Throws when Gemini
  /// fails.
  Future<List<ShoppingItem>> aggregate(List<Ingredient> lines, String languageCode, String source) async {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: RecipeAiService.model,
      systemInstruction: Content.system(instruction(languageCode)),
      generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: _schema, temperature: 0),
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
  /// name. A line no item covers becomes its own item, so nothing is ever
  /// dropped; with an empty answer, that is every line, which is the
  /// fallback when Gemini fails.
  static List<ShoppingItem> merge(List<Ingredient> lines, Map<String, dynamic> answer, String source) {
    final covered = <int>{};
    final drafts = <({Ingredient first, Aisle aisle, String icon, String name, double amount, IngredientUnit unit})>[];
    for (final item in (answer['items'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final refs = [
        for (final r in item['refs'] as List? ?? const [])
          if ((r as num).toInt() case final ref when ref >= 0 && ref < lines.length) ref,
      ]..sort();
      final name = (item['name'] as String? ?? '').trim();
      if (refs.isEmpty || name.isEmpty) continue;
      covered.addAll(refs);
      drafts.add((
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
      drafts.add((
        first: line,
        aisle: line.aisle,
        icon: line.icon,
        name: line.name,
        amount: line.amount,
        unit: line.unit,
      ));
    }

    drafts.sort((a, b) {
      final byAisle = a.aisle.index.compareTo(b.aisle.index);
      return byAisle != 0 ? byAisle : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final ids = <String>{};
    return [
      for (final (index, d) in drafts.indexed)
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
  and plural, size, colour or preparation ("chopped", "minced"), and variants
  bought as one product (onion and onions; salt, sea salt and kosher salt).
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
- name: the product in $language, lower case, short and generic (e.g. "sel",
  not "sel de mer fin").
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
        ),
      ),
    },
  );
}
