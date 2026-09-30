import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/aisle.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/weekday.dart';
import 'package:tably/features/plan/model/week_plan.dart';
import 'package:tably/features/recipe/model/recipe.dart';
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

Ingredient _ingredient(int id, String name, double amount, String unit, Aisle aisle) =>
    Ingredient(id: id, icon: '🍽️', name: name, amount: amount, unit: unit, aisle: aisle);

PlanSlot _slot(Weekday day, Recipe recipe, {bool leftover = false}) =>
    PlanSlot(day: day, slot: MealSlot.dinner, recipe: recipe, isLeftover: leftover, showSlotLabel: false);

void main() {
  final soyA = _ingredient(16124, 'sauce soja', 14.5, 'ml', Aisle.tinsSauces);
  final porc = _recipe('porc', [soyA, _ingredient(10010062, 'côtelettes', 1, '', Aisle.meatFish)]);
  final poulet = _recipe('poulet', [
    _ingredient(16124, 'sauce soja', 38.67, 'ml', Aisle.tinsSauces),
    _ingredient(11291, 'cébettes', 0.5, 'bottes', Aisle.produce),
    _ingredient(2047, 'sel', 0, 'au goût', Aisle.herbsGrocery),
  ]);
  final week = WeekPlan(slots: [
    _slot(Weekday.monday, porc),
    _slot(Weekday.tuesday, porc, leftover: true),
    _slot(Weekday.wednesday, poulet),
  ]);

  test('sums every portion eaten, leftovers included, for the whole household', () {
    final items = ShoppingListBuilder.fromWeek(week, 2);
    final soy = items.firstWhere((i) => i.id == '16124_ml');
    // (14.5 × 2 slots + 38.67) × 2 people = 135.34
    expect(soy.needed, '135ml');
    expect(items.firstWhere((i) => i.id == '10010062_').needed, '4', reason: '1 chop × 2 slots × 2 people');
  });

  test('one line per ingredient and unit, sorted by aisle then name', () {
    final items = ShoppingListBuilder.fromWeek(week, 1);
    expect(items.map((i) => i.name), ['cébettes', 'côtelettes', 'sauce soja', 'sel']);
    expect(items.map((i) => i.order), [0, 1, 2, 3]);
  });

  test('an ingredient with no amount is listed without one', () {
    final salt = ShoppingListBuilder.fromWeek(week, 1).firstWhere((i) => i.name == 'sel');
    expect(salt.needed, isEmpty);
  });

  test('ids are stable and safe as Firestore document ids', () {
    final first = ShoppingListBuilder.fromWeek(week, 1).map((i) => i.id).toList();
    expect(ShoppingListBuilder.fromWeek(week, 3).map((i) => i.id), first);
    expect(first, contains('2047_au_go_t'));
    expect(first.every((id) => !id.contains('/') && !id.contains(' ')), isTrue);
  });

  test('groups into aisle cards in aisle order', () {
    final categories = ShoppingListBuilder.groupByAisle(ShoppingListBuilder.fromWeek(week, 1));
    expect(categories.map((c) => c.aisle), [Aisle.produce, Aisle.meatFish, Aisle.tinsSauces, Aisle.herbsGrocery]);
  });

  test('an empty week gives an empty list', () {
    expect(ShoppingListBuilder.fromWeek(const WeekPlan(), 2), isEmpty);
  });
}
