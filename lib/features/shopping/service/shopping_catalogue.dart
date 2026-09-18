import '../model/shopping_item.dart';

/// The aisle-ordered grocery list the planner produces, matching the design.
abstract final class ShoppingCatalogue {
  static const categoryProduce = 'FRUITS ET LÉGUMES';
  static const categoryMeatFish = 'VIANDE ET POISSON';
  static const categoryPastaRice = 'PÂTES, RIZ ET NOUILLES';
  static const categoryTinsSauces = 'CONSERVES, BOCAUX ET SAUCES';
  static const categoryHerbsGrocery = 'HERBES, ÉPICES ET ÉPICERIE';

  /// Aisle order as printed on the list.
  static const categoryOrder = <String>[
    categoryProduce,
    categoryMeatFish,
    categoryPastaRice,
    categoryTinsSauces,
    categoryHerbsGrocery,
  ];

  static const _raw = <(String, String, String, String, String)>[
    (categoryProduce, '🥑', 'Avocat', '0.5', '1'),
    (categoryProduce, '🥦', 'Brocoli', '350g', '1'),
    (categoryProduce, '🥕', 'Carottes', '65g', '1 sachet'),
    (categoryProduce, '🥫', 'Tomates coupées en morceaux', '100ml', '400ml'),
    (categoryProduce, '🧄', 'Ail', '4 gousses', "1 tête d'ail"),
    (categoryProduce, '🍋', 'Citron', '0.8', '1'),
    (categoryProduce, '🍈', 'Citron vert', '1.3', '2'),
    (categoryProduce, '🫛', 'Pois', '40g', '900g'),
    (categoryProduce, '🧅', 'Oignon rouge', '½', '1'),
    (categoryProduce, '🌶️', 'Piment rouge', '1', '1'),
    (categoryProduce, '🫑', 'Poivrons grillés au barbecue', '95g', '240g'),
    (categoryProduce, '🧅', 'Cébette', '2 tiges', '1 botte'),
    (categoryMeatFish, '🍗', 'Poitrine de poulet', '3', '600g'),
    (categoryMeatFish, '🌭', 'Chorizo', '50g', '225g'),
    (categoryPastaRice, '🍜', 'Nouilles', '90g', '300g'),
    (categoryPastaRice, '🍚', 'Riz', '225g', '500g'),
    (categoryTinsSauces, '🫘', 'Haricots beurre', '1.5 boîtes', '2 boîtes'),
    (categoryTinsSauces, '🍶', 'Sauce soja claire', '45ml', '150ml'),
    (categoryTinsSauces, '🥫', 'Mayo', '1¼ c. à s.', '17.5g'),
    (categoryTinsSauces, '🌶️', 'Sauce au piment doux', '20ml', '300ml'),
    (categoryHerbsGrocery, '🌿', "Pointes d'asperges", '50g', '180g'),
    (categoryHerbsGrocery, '🥣', "Mélange d'épices cajun", '½ c. à s.', '45g'),
    (categoryHerbsGrocery, '🥚', "Jaunes d'œufs", '1', '1'),
    (categoryHerbsGrocery, '🥚', 'Œufs', '1', '6'),
    (categoryHerbsGrocery, '🧈', 'Tofu extra-ferme', '150g', '300g'),
    (categoryHerbsGrocery, '🎀', 'Farfalle', '95g', '500g'),
    (categoryHerbsGrocery, '🧀', 'Feta', '50g', '200g'),
    (categoryHerbsGrocery, '🫘', 'Fèves surgelées', '125g', '900g'),
    (categoryHerbsGrocery, '🫒', "Huile d'olive", '1½ c. à s.', '500ml'),
    (categoryHerbsGrocery, '🧈', 'Parmesan', '20g', '150g'),
    (categoryHerbsGrocery, '🌿', 'Persil', '20g', '1 botte'),
    (categoryHerbsGrocery, '🥜', 'Beurre de cacahuètes', '20g', '340g'),
    (categoryHerbsGrocery, '🥓', 'Prosciutto', '25g', '105g'),
    (categoryHerbsGrocery, '🥓', 'Pancetta non fumée', '42.5g', '200g'),
  ];

  /// A fresh, unchecked list — written to Firestore whenever a plan is generated.
  static List<ShoppingItem> buildList() => [
        for (final (index, row) in _raw.indexed)
          ShoppingItem(
            id: 'item_${index.toString().padLeft(2, '0')}',
            category: row.$1,
            icon: row.$2,
            name: row.$3,
            needed: row.$4,
            quantity: row.$5,
            order: index,
          ),
      ];

  /// Groups items into aisle cards, preserving catalogue order.
  static List<ShoppingCategory> groupByCategory(List<ShoppingItem> items) {
    final byCategory = <String, List<ShoppingItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }
    for (final list in byCategory.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }
    return [
      for (final name in categoryOrder)
        if (byCategory[name] case final items? when items.isNotEmpty)
          ShoppingCategory(name: name, items: items),
    ];
  }
}
