import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/aisle.dart';
import 'package:tably/core/model/ingredient_unit.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/plan/model/week_plan.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/shopping/service/shopping_ai_service.dart';
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

PlanSlot _slot(Weekday day, Recipe recipe, {bool leftover = false}) => PlanSlot(
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
    _ingredient(16124, 'sauce soja', 1, IngredientUnit.tbsp, Aisle.tinsSauces),
    _ingredient(11291, 'cébettes', 0.5, IngredientUnit.bunch, Aisle.produce),
    _ingredient(2047, 'sel', 0, IngredientUnit.toTaste, Aisle.herbsGrocery),
    _ingredient(-1, 'sauce maison', 1, IngredientUnit.tbsp, Aisle.tinsSauces),
    _ingredient(-2, 'citron confit', 1, IngredientUnit.piece, Aisle.produce),
  ]);
  final week = WeekPlan(
    slots: [
      _slot(Weekday.monday, porc),
      _slot(Weekday.tuesday, porc, leftover: true),
      _slot(Weekday.wednesday, poulet),
    ],
  );

  group('lines', () {
    test('sum every portion eaten, leftovers included, for the whole household', () {
      final lines = ShoppingListBuilder.linesFromWeek(week, 2);
      final soy = lines.firstWhere((l) => l.id == 16124 && l.unit == IngredientUnit.ml);
      // (14.5 × 2 slots + 38.67) × 2 people = 135.34
      expect(soy.amount, closeTo(135.34, 0.001));
      expect(lines.firstWhere((l) => l.id == 10010062).amount, 4, reason: '1 chop × 2 slots × 2 people');
    });

    test('only the same ingredient in the same unit sums, in order of appearance', () {
      final lines = ShoppingListBuilder.linesFromWeek(week, 1);
      expect(lines.map((l) => (l.name, l.unit)), [
        ('sauce soja', IngredientUnit.ml),
        ('côtelettes', IngredientUnit.piece),
        ('sauce soja', IngredientUnit.tbsp),
        ('cébettes', IngredientUnit.bunch),
        ('sel', IngredientUnit.toTaste),
        ('sauce maison', IngredientUnit.tbsp),
        ('citron confit', IngredientUnit.piece),
      ]);
    });

    test('an empty week has no lines', () {
      expect(ShoppingListBuilder.linesFromWeek(const WeekPlan(), 2), isEmpty);
    });
  });

  test('the source changes with the language, the household and the recipes, not their order', () {
    final source = ShoppingListBuilder.sourceOf(week, 2, 'fr');
    expect(source, 'fr|2|porcx2,pouletx1');
    expect(ShoppingListBuilder.sourceOf(WeekPlan(slots: week.slots.reversed.toList()), 2, 'fr'), source);
    expect(ShoppingListBuilder.sourceOf(week, 3, 'fr'), isNot(source));
    expect(ShoppingListBuilder.sourceOf(week, 2, 'en'), isNot(source));
  });

  test('groups into aisle cards in aisle order', () {
    final items = ShoppingAiService.merge(ShoppingListBuilder.linesFromWeek(week, 1), const {}, '');
    final categories = ShoppingListBuilder.groupByAisle(items);
    expect(categories.map((c) => c.aisle), [Aisle.produce, Aisle.meatFish, Aisle.tinsSauces, Aisle.herbsGrocery]);
  });
}
