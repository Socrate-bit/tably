import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/aisle.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';

void main() {
  // Two real searchRecipes results: Glazed pork chops (644761) and
  // Three-Cup Chicken (663392).
  final raw = (jsonDecode(File('test/fixtures/spoonacular_recipes.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  // Round-tripped through JSON so it is typed exactly like a decoded reply.
  Map<String, dynamic> answer() => jsonDecode(jsonEncode({
        'kept': [
          {
            'id': 644761,
            'title': 'Côtelettes de porc glacées',
            'craving': 'high_protein',
            'protein': 'pork',
            'cuisine': 'none',
            'ingredients': [
              {'id': 10010062, 'name': 'côtelettes de porc', 'unit': '', 'icon': '🥩', 'aisle': 'meat_fish'},
              {'id': 19296, 'name': 'miel', 'unit': 'c. à s.', 'icon': '🍯', 'aisle': 'herbs_grocery'},
            ],
            'steps': ['Faites dorer les côtelettes.', 'Nappez de sauce et servez.'],
          },
          // An id Gemini made up is ignored.
          {'id': 1, 'title': 'Fantôme', 'craving': 'quick', 'protein': 'beef', 'cuisine': 'none', 'ingredients': [], 'steps': []},
        ],
        'rejected': [
          {'id': 663392, 'reason': 'contains alcohol (rice wine)'},
        ],
      })) as Map<String, dynamic>;

  test('keeps only what Gemini kept, with its text and Spoonacular numbers', () {
    final recipes = RecipeAiService.merge(raw, answer());

    expect(recipes.map((r) => r.id), ['644761']);
    final recipe = recipes.single;
    expect(recipe.title, 'Côtelettes de porc glacées');
    expect(recipe.craving, Craving.highProtein);
    expect(recipe.protein, RecipeProtein.pork);
    expect(recipe.cuisine, isNull);
    expect(recipe.steps, hasLength(2));
    // Numbers, photo and source are never taken from the model.
    expect(recipe.photoUrl, 'https://img.spoonacular.com/recipes/644761-636x393.jpg');
    expect(recipe.price, 1.77);
    expect(recipe.macros, const Macros(kcal: 459, protein: 31, carbs: 11, fat: 32));
    expect(recipe.time, '45m');
    expect(recipe.creator, isNotNull);
  });

  test('translates the ingredients Gemini covered and keeps the rest in English', () {
    final ingredients = RecipeAiService.merge(raw, answer()).single.ingredients;
    final source = raw.firstWhere((r) => r['id'] == 644761)['ingredients'] as List;

    expect(ingredients, hasLength(source.length), reason: 'no ingredient is ever dropped');
    final honey = ingredients.firstWhere((i) => i.id == 19296);
    expect((honey.name, honey.unit, honey.icon, honey.aisle), ('miel', 'c. à s.', '🍯', Aisle.herbsGrocery));
    expect(honey.amount, 0.5, reason: 'per-portion amount comes from Spoonacular');
    final soy = ingredients.firstWhere((i) => i.id == 16124);
    expect((soy.name, soy.unit, soy.aisle), ('soy sauce', 'ml', Aisle.herbsGrocery));
  });

  test('a recipe both kept and rejected, or kept twice, is handled safely', () {
    final contradictory = answer();
    final kept = contradictory['kept'] as List;
    kept.add(kept.first);
    (contradictory['rejected'] as List).add({'id': 644761, 'reason': 'contains peanuts'});
    expect(RecipeAiService.merge(raw, contradictory), isEmpty, reason: 'rejection wins');

    final duplicated = answer();
    (duplicated['kept'] as List).add((duplicated['kept'] as List).first);
    expect(RecipeAiService.merge(raw, duplicated), hasLength(1));
  });

  test('falls back to the source text when a translation is empty', () {
    final empty = answer();
    ((empty['kept'] as List).first as Map)
      ..['title'] = ''
      ..['steps'] = <String>[];
    final recipe = RecipeAiService.merge(raw, empty).single;
    expect(recipe.title, 'Glazed pork chops');
    expect(recipe.steps, (raw.first['steps'] as List).cast<String>());
  });

  test('the instruction carries every constraint and the language', () {
    const profile = UserProfile(
      languageCode: 'fr',
      diets: {Diet.vegetarian},
      allergies: {Allergy.nutFree, Allergy.glutenFree},
      appliances: {Appliance.hob},
    );
    final text = RecipeAiService.instruction(profile);
    expect(text, contains('vegetarian'));
    expect(text, contains('nut_free, gluten_free'));
    expect(text, contains('The user has: hob'));
    expect(text, contains('French'));

    final none = RecipeAiService.instruction(const UserProfile(languageCode: 'en', diets: {Diet.none}));
    expect(none, contains('diets: none'));
    expect(none, contains('English'));
  });
}
