import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/aisle.dart';
import 'package:tably/core/model/ingredient_unit.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/plan/model/week_plan.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/shopping/model/shopping_item.dart';
import 'package:tably/features/shopping/service/shopping_list_builder.dart';

Recipe _recipe(String id, List<Ingredient> ingredients) => Recipe(
      id: id,
      title: id,
      photoUrl: '',
      macros: const Macros(kcal: 0, protein: 0, carbs: 0, fat: 0),
      time: '20m',
      cookTime: '20m',
      price: 2,
      craving: Craving.quick,
      protein: RecipeProtein.chicken,
      ingredients: ingredients,
      steps: const [],
    );

Ingredient _ingredient(int id, String name, double amount, IngredientUnit unit, Aisle aisle) =>
    Ingredient(id: id, icon: '🍽️', name: name, amount: amount, unit: unit, aisle: aisle);

PlanSlot _slot(Weekday day, Recipe recipe, {bool leftover = false}) =>
    PlanSlot(
      day: day,
      slot: MealSlot.dinner,
      recipe: recipe,
      isLeftover: leftover,
      portions: leftover ? 0 : 1,
      showSlotLabel: false,
    );

void main() {
  final soyA = _ingredient(16124, 'sauce soja', 14.5, IngredientUnit.ml, Aisle.tinsSauces);
  final porc = _recipe('porc', [soyA, _ingredient(10010062, 'côtelettes', 1, IngredientUnit.piece, Aisle.meatFish)]);
  final poulet = _recipe('poulet', [
    _ingredient(16124, 'sauce soja', 38.67, IngredientUnit.ml, Aisle.tinsSauces),
    _ingredient(11291, 'cébettes', 0.5, IngredientUnit.bunch, Aisle.produce),
    _ingredient(2047, 'sel', 0, IngredientUnit.toTaste, Aisle.herbsGrocery),
  ]);
  final week = WeekPlan(slots: [
    _slot(Weekday.monday, porc),
    _slot(Weekday.tuesday, porc, leftover: true),
    _slot(Weekday.wednesday, poulet),
  ]);

  test('sums every portion eaten, leftovers included, for the whole household', () {
    final items = ShoppingListBuilder.fromWeek(week, 2);
    final soy = items.firstWhere((i) => i.id == '16124');
    // (14.5 × 2 slots + 38.67) × 2 people = 135.34
    expect(soy.quantities.single.unit, IngredientUnit.ml);
    expect(soy.quantities.single.amount, closeTo(135.34, 0.001));
    expect(items.firstWhere((i) => i.id == '10010062').quantities, [const Quantity(4, IngredientUnit.piece)],
        reason: '1 chop × 2 slots × 2 people');
  });

  test('one line per ingredient, sorted by aisle then name', () {
    final items = ShoppingListBuilder.fromWeek(week, 1);
    expect(items.map((i) => i.name), ['cébettes', 'côtelettes', 'sauce soja', 'sel']);
    expect(items.map((i) => i.order), [0, 1, 2, 3]);
  });

  test('an ingredient with no amount is listed without one', () {
    final salt = ShoppingListBuilder.fromWeek(week, 1).firstWhere((i) => i.name == 'sel');
    expect(salt.quantities, isEmpty);
  });

  test('ids are stable and safe as Firestore document ids', () {
    final first = ShoppingListBuilder.fromWeek(week, 1).map((i) => i.id).toList();
    expect(ShoppingListBuilder.fromWeek(week, 3).map((i) => i.id), first);
    expect(first, containsAll(['16124', '2047']));
    expect(first.every((id) => !id.contains('/') && !id.contains(' ')), isTrue);
  });

  group('mixed units', () {
    List<ShoppingItem> listOf(List<Ingredient> ingredients) => ShoppingListBuilder.fromWeek(
          WeekPlan(slots: [
            for (final (index, ingredient) in ingredients.indexed)
              _slot(Weekday.values[index], _recipe('r$index', [ingredient])),
          ]),
          1,
        );

    test('spoons and millilitres sum into one line in ml', () {
      final items = listOf([
        _ingredient(16124, 'sauce soja', 2, IngredientUnit.tbsp, Aisle.tinsSauces),
        _ingredient(16124, 'sauce soja', 1, IngredientUnit.tsp, Aisle.tinsSauces),
        _ingredient(16124, 'sauce soja', 10, IngredientUnit.ml, Aisle.tinsSauces),
      ]);
      expect(items.single.quantities, [const Quantity(45, IngredientUnit.ml)]);
    });

    test('grams and kilos sum into grams', () {
      final items = listOf([
        _ingredient(20420, 'pâtes', 0.5, IngredientUnit.kg, Aisle.pastaRice),
        _ingredient(20420, 'pâtes', 100, IngredientUnit.g, Aisle.pastaRice),
      ]);
      expect(items.single.quantities, [const Quantity(600, IngredientUnit.g)]);
    });

    test('a unit used alone keeps its name', () {
      final items = listOf([
        _ingredient(2009, 'piment', 1, IngredientUnit.tsp, Aisle.herbsGrocery),
        _ingredient(2009, 'piment', 0.5, IngredientUnit.tsp, Aisle.herbsGrocery),
      ]);
      expect(items.single.quantities, [const Quantity(1.5, IngredientUnit.tsp)]);
    });

    test('counts and weights share one line as separate parts', () {
      final items = listOf([
        _ingredient(11282, 'oignon', 2, IngredientUnit.piece, Aisle.produce),
        _ingredient(11282, 'oignon', 150, IngredientUnit.g, Aisle.produce),
        _ingredient(11282, 'oignon', 0, IngredientUnit.toTaste, Aisle.produce),
      ]);
      expect(items.single.quantities, [const Quantity(2, IngredientUnit.piece), const Quantity(150, IngredientUnit.g)]);
    });

    test('ingredients without an id merge by name, never with each other', () {
      final items = listOf([
        _ingredient(-1, 'sauce maison', 1, IngredientUnit.tbsp, Aisle.tinsSauces),
        _ingredient(-1, 'citron confit', 1, IngredientUnit.piece, Aisle.produce),
        _ingredient(-2, 'sauce maison', 1, IngredientUnit.tbsp, Aisle.tinsSauces),
      ]);
      expect(items.map((i) => i.id), ['name_citron_confit', 'name_sauce_maison']);
    });
  });

  test('groups into aisle cards in aisle order', () {
    final categories = ShoppingListBuilder.groupByAisle(ShoppingListBuilder.fromWeek(week, 1));
    expect(categories.map((c) => c.aisle), [Aisle.produce, Aisle.meatFish, Aisle.tinsSauces, Aisle.herbsGrocery]);
  });

  test('an empty week gives an empty list', () {
    expect(ShoppingListBuilder.fromWeek(const WeekPlan(), 2), isEmpty);
  });
}
