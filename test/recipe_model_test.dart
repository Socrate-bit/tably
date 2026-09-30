import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/util/quantity.dart';
import 'package:tably/features/recipe/model/recipe.dart';

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
    expect(formatQuantity(150, 'g'), '150g');
    expect(formatQuantity(28.38, 'g'), '28g');
    expect(formatQuantity(14.5, 'ml'), '15ml');
    expect(formatQuantity(0.5, ''), '½');
    expect(formatQuantity(1.5, ''), '1½');
    expect(formatQuantity(2, 'gousses'), '2 gousses');
    expect(formatQuantity(0.25, 'c. à s.'), '¼ c. à s.');
    expect(formatQuantity(0.06, 'c. à c.'), '⅛ c. à c.', reason: 'a pinch never shows as 0');
    expect(formatQuantity(1.4, ''), '1.4');
    expect(formatQuantity(0, 'au goût'), 'au goût');
  });
}
