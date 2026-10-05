import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/aisle.dart';
import 'package:tably/core/model/ingredient_unit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/shopping/service/shopping_ai_service.dart';

Ingredient _line(int id, String name, double amount, IngredientUnit unit, Aisle aisle) =>
    Ingredient(id: id, icon: '🍽️', name: name, amount: amount, unit: unit, aisle: aisle);

void main() {
  final lines = [
    _line(11282, 'oignon', 2, IngredientUnit.piece, Aisle.produce), // ref 0
    _line(11282, 'oignon', 150, IngredientUnit.g, Aisle.produce), // ref 1
    _line(10011282, 'oignons', 1, IngredientUnit.piece, Aisle.produce), // ref 2
    _line(2047, 'sel', 1, IngredientUnit.tsp, Aisle.herbsGrocery), // ref 3
    _line(1012047, 'sel de mer', 1, IngredientUnit.pinch, Aisle.herbsGrocery), // ref 4
    _line(1102047, 'sel et poivre', 0, IngredientUnit.toTaste, Aisle.herbsGrocery), // ref 5
    _line(16124, 'sauce soja', 30, IngredientUnit.ml, Aisle.tinsSauces), // ref 6
  ];

  // Round-tripped through JSON so it is typed exactly like a decoded reply.
  Map<String, dynamic> answer() =>
      jsonDecode(
            jsonEncode({
              'items': [
                {
                  'refs': [3, 4, 5],
                  'name': 'sel',
                  'icon': '🧂',
                  'aisle': 'herbs_grocery',
                  'amount': 1.5,
                  'unit': 'tsp',
                },
                {
                  'refs': [5],
                  'name': 'poivre',
                  'icon': '🌶️',
                  'aisle': 'herbs_grocery',
                  'amount': 0,
                  'unit': 'to_taste',
                },
                {
                  'refs': [2, 0, 1],
                  'name': 'oignon',
                  'icon': '🧅',
                  'aisle': 'produce',
                  'amount': 4,
                  'unit': 'piece',
                },
                // Refs Gemini made up, or an item with no name, are ignored.
                {
                  'refs': [42],
                  'name': 'fantôme',
                  'icon': '👻',
                  'aisle': 'produce',
                  'amount': 1,
                  'unit': 'piece',
                },
                {
                  'refs': [6],
                  'name': ' ',
                  'icon': '🍶',
                  'aisle': 'tins_sauces',
                  'amount': 30,
                  'unit': 'ml',
                },
              ],
            }),
          )
          as Map<String, dynamic>;

  test('merges similar ingredients into one item in one unit', () {
    final items = ShoppingAiService.merge(lines, answer(), 'fr|2|r1x1');
    final onion = items.firstWhere((i) => i.name == 'oignon');
    expect((onion.amount, onion.unit, onion.icon), (4.0, IngredientUnit.piece, '🧅'));
    expect(items.where((i) => i.name.startsWith('sel')), hasLength(1));
    expect(items.every((i) => i.source == 'fr|2|r1x1'), isTrue);
  });

  test('items Gemini left apart under the same name and unit are summed', () {
    final items = ShoppingAiService.merge(lines, jsonDecode(jsonEncode({
      'items': [
        {'refs': [3], 'name': 'sel', 'icon': '🧂', 'aisle': 'herbs_grocery', 'amount': 1, 'unit': 'tsp'},
        {'refs': [4], 'name': 'Sel', 'icon': '🧂', 'aisle': 'herbs_grocery', 'amount': 0.5, 'unit': 'tsp'},
        {'refs': [6], 'name': 'sauce soja', 'icon': '🍶', 'aisle': 'tins_sauces', 'amount': 30, 'unit': 'ml'},
        {'refs': [5], 'name': 'sauce soja', 'icon': '🍶', 'aisle': 'tins_sauces', 'amount': 1, 'unit': 'tbsp'},
      ],
    })) as Map<String, dynamic>, '');
    final salt = items.where((i) => i.name.toLowerCase() == 'sel').single;
    expect((salt.amount, salt.unit, salt.id), (1.5, IngredientUnit.tsp, '2047'));
    expect(items.where((i) => i.name == 'sauce soja'), hasLength(2), reason: 'different units are never summed');
  });

  test('an uncovered line keeps its own item, so nothing is dropped', () {
    final soy = ShoppingAiService.merge(lines, answer(), '').firstWhere((i) => i.id == '16124');
    expect((soy.name, soy.amount, soy.unit), ('sauce soja', 30.0, IngredientUnit.ml));
  });

  test('ids come from the first ingredient covered and stay unique when a line splits', () {
    final items = ShoppingAiService.merge(lines, answer(), '');
    expect(items.map((i) => i.id), unorderedEquals(['11282', '2047', '1102047', '16124']));

    final split = ShoppingAiService.merge(
      lines,
      jsonDecode(
            jsonEncode({
              'items': [
                {
                  'refs': [5],
                  'name': 'sel',
                  'icon': '🧂',
                  'aisle': 'herbs_grocery',
                  'amount': 0,
                  'unit': 'to_taste',
                },
                {
                  'refs': [5],
                  'name': 'poivre',
                  'icon': '🌶️',
                  'aisle': 'herbs_grocery',
                  'amount': 0,
                  'unit': 'to_taste',
                },
              ],
            }),
          )
          as Map<String, dynamic>,
      '',
    );
    expect(split.map((i) => i.id).where((id) => id.startsWith('1102047')), [
      '1102047',
      '1102047_sel',
    ], reason: 'poivre sorts first');
  });

  test('sorted by aisle then name, with no amount when there is none', () {
    final items = ShoppingAiService.merge(lines, answer(), '');
    expect(items.map((i) => i.name), ['oignon', 'sauce soja', 'poivre', 'sel']);
    expect(items.map((i) => i.order), [0, 1, 2, 3]);
    expect(items.firstWhere((i) => i.name == 'poivre').hasAmount, isFalse);
  });

  test('with no answer, every line is its own item', () {
    final items = ShoppingAiService.merge(lines, const {}, '');
    expect(items, hasLength(lines.length));
    expect(items.map((i) => i.id).toSet(), hasLength(lines.length), reason: 'ids stay unique');
  });

  test('the prompt carries the language and the aisle guide', () {
    expect(ShoppingAiService.instruction('fr'), contains('in French'));
    expect(ShoppingAiService.instruction('en'), contains('in English'));
    expect(ShoppingAiService.instruction('fr'), contains('herbs_grocery'));
  });
}
