import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/model/store.dart';
import 'package:tably/features/recipe/cubit/recipe_browse_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';

import 'fixtures/recipe_fixtures.dart';

String _label(Craving c) => switch (c) {
      Craving.quick => 'Repas express',
      Craving.highProtein => 'Riche en-protéines',
      Craving.indulgent => 'Gourmand',
      _ => c.id,
    };

List<String> _ids(RecipeBrowseState state, {Store store = Store.carrefour}) =>
    state.apply(RecipeFixtures.recipes, store: store, cravingLabel: _label).map((r) => r.id).toList();

void main() {
  test('no filters and no search shows the whole catalogue', () {
    expect(_ids(const RecipeBrowseState()), hasLength(RecipeFixtures.recipes.length));
  });

  test('search matches every word across title and badge', () {
    expect(_ids(const RecipeBrowseState(query: 'poulet riz')), containsAll(['riz_poulet_cajun', 'riz_frit_poulet']));
    expect(_ids(const RecipeBrowseState(query: 'gourmand')), ['wraps_big_mac']);
    expect(_ids(const RecipeBrowseState(query: 'zzz')), isEmpty);
  });

  test('craving, cuisine and protein filters combine', () {
    const state = RecipeBrowseState(cuisines: {Cuisine.italian}, proteins: {RecipeProtein.pork});
    expect(_ids(state), unorderedEquals(['carbonara_haricots_asperges', 'fusilli_pois_lard_ricotta']));
    expect(_ids(const RecipeBrowseState(cravings: {Craving.indulgent})), ['wraps_big_mac']);
    expect(_ids(const RecipeBrowseState(cuisines: {Cuisine.mexican})), isEmpty);
  });

  test('price limit uses the store price the cards show', () {
    // Wraps are €6.40 at reference prices: in at Lidl (×0.975 = €6.24), out at Franprix (×1.25 = €8.00).
    const state = RecipeBrowseState(maxPrice: 6.5, cravings: {Craving.indulgent});
    expect(_ids(state, store: Store.lidl), ['wraps_big_mac']);
    expect(_ids(state, store: Store.franprix), isEmpty);
  });

  test('a craving filter also keeps recipes that meet it under another badge', () {
    final strong = RecipeFixtures.recipes.where((r) => r.macros.protein >= 30 && r.craving != Craving.highProtein);
    expect(strong, isNotEmpty, reason: 'fixtures need a high-protein dish badged otherwise');
    final kept = _ids(const RecipeBrowseState(cravings: {Craving.highProtein}));
    expect(kept, containsAll(strong.map((r) => r.id)));
    expect(
      kept,
      unorderedEquals([
        for (final r in RecipeFixtures.recipes)
          if (r.craving == Craving.highProtein || r.macros.protein >= 30) r.id,
      ]),
    );
  });

  test('API results are not filtered again on what the API already matched', () {
    // Nothing in the fixtures is Mexican, nor matches the text, yet the API said so.
    const state = RecipeBrowseState(query: 'zzz', cuisines: {Cuisine.mexican}, cravings: {Craving.indulgent});
    final searched = state.apply(RecipeFixtures.recipes, store: Store.carrefour, cravingLabel: _label, searched: true);
    expect(searched, hasLength(RecipeFixtures.recipes.length));

    // Several cravings are not sent to the API, so they still apply.
    const several = RecipeBrowseState(cravings: {Craving.indulgent, Craving.lowCalorie});
    final local = several.apply(RecipeFixtures.recipes, store: Store.carrefour, cravingLabel: _label, searched: true);
    expect(local.every((r) => r.satisfies(Craving.indulgent) || r.satisfies(Craving.lowCalorie)), isTrue);
    expect(local.length, lessThan(RecipeFixtures.recipes.length));
  });

  test('filter count counts chips plus one for a price limit', () {
    final widest = RecipeBrowseState.widest;
    expect(RecipeBrowseState(constraints: widest).filterCount, 0);
    expect(
      RecipeBrowseState(constraints: widest, cravings: {Craving.quick}, proteins: {RecipeProtein.tofu}, maxPrice: 8)
          .filterCount,
      3,
    );
  });
}
