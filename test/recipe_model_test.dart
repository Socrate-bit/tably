import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/ingredient_unit.dart';
import 'package:tably/core/util/quantity.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/l10n/app_localizations.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  test('a recipe survives a Firestore round trip', () {
    for (final recipe in RecipeFixtures.recipes) {
      expect(Recipe.fromMap(recipe.id, recipe.toMap()), recipe, reason: recipe.id);
    }
  });

  test('unknown enum ids fall back instead of throwing', () {
    final recipe = Recipe.fromMap('x', const {'craving': 'nope', 'protein': 'nope', 'cuisine': 'klingon'});
    expect(recipe.cuisine, isNull);
    expect(recipe.protein, RecipeProtein.vegetarian);
    expect(recipe.ingredients, isEmpty);
  });

  test('quantities read like the design', () {
    final fr = lookupAppL10n(const Locale('fr'));
    expect(formatQuantity(150, IngredientUnit.g, fr), '150g');
    expect(formatQuantity(28.38, IngredientUnit.g, fr), '28g');
    expect(formatQuantity(14.5, IngredientUnit.ml, fr), '15ml');
    expect(formatQuantity(0.5, IngredientUnit.piece, fr), '½');
    expect(formatQuantity(1.5, IngredientUnit.piece, fr), '1½');
    expect(formatQuantity(1, IngredientUnit.clove, fr), '1 gousse');
    expect(formatQuantity(2, IngredientUnit.clove, fr), '2 gousses');
    expect(formatQuantity(0.25, IngredientUnit.tbsp, fr), '¼ c. à s.');
    expect(formatQuantity(0.06, IngredientUnit.tsp, fr), '⅛ c. à c.', reason: 'a pinch never shows as 0');
    expect(formatQuantity(1.4, IngredientUnit.piece, fr), '1.4');
    expect(formatQuantity(0, IngredientUnit.toTaste, fr), 'au goût');
    expect(formatQuantity(2, IngredientUnit.clove, lookupAppL10n(const Locale('en'))), '2 cloves');
    expect(formatQuantity(1.5, IngredientUnit.kg, fr), '1½kg');
  });

  test('units read from ids, legacy labels and Spoonacular labels', () {
    expect(IngredientUnit.fromId('tbsp'), IngredientUnit.tbsp);
    expect(IngredientUnit.fromId('to_taste'), IngredientUnit.toTaste);
    expect(IngredientUnit.fromId('c. à s.'), IngredientUnit.tbsp);
    expect(IngredientUnit.fromId('gousses'), IngredientUnit.clove);
    expect(IngredientUnit.fromId('Tbsps'), IngredientUnit.tbsp);
    expect(IngredientUnit.fromId(''), IngredientUnit.piece);
    expect(IngredientUnit.fromId('large bunches'), IngredientUnit.piece);
    expect(IngredientUnit.fromId(null), IngredientUnit.piece);
  });
}
