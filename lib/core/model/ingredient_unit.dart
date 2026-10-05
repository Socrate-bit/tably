/// The fixed set of units an ingredient can be measured in. Only the id is
/// persisted; the label comes from l10n.
enum IngredientUnit {
  g('g'),
  kg('kg'),
  ml('ml'),
  l('l'),
  tbsp('tbsp'),
  tsp('tsp'),
  piece('piece'),
  clove('clove'),
  slice('slice'),
  bunch('bunch'),
  sprig('sprig'),
  leaf('leaf'),
  pinch('pinch'),
  can('can'),
  pack('pack'),
  toTaste('to_taste');

  const IngredientUnit(this.id);
  final String id;

  /// Weights and volumes are written glued to the number ("150g", "15ml").
  bool get isMetric => const {g, kg, ml, l}.contains(this);

  /// Reads a stored id. Recipes saved before units were fixed hold a free
  /// label instead ("c. à s.", "gousses"), and Spoonacular's own labels
  /// ("Tbsps", "cloves") arrive when Gemini skips an ingredient; both map
  /// here. Anything else is a plain count.
  static IngredientUnit fromId(String? id) {
    final key = (id ?? '').trim().toLowerCase();
    return values.where((u) => u.id == key).firstOrNull ?? _labels[key] ?? piece;
  }

  static const _labels = {
    'c. à s.': tbsp, 'cuillère à soupe': tbsp, 'cuillères à soupe': tbsp, 'tbsps': tbsp,
    'tablespoon': tbsp, 'tablespoons': tbsp,
    'c. à c.': tsp, 'c. à café': tsp, 'cuillère à café': tsp, 'cuillères à café': tsp, 'tsps': tsp,
    'teaspoon': tsp, 'teaspoons': tsp,
    'gousse': clove, 'gousses': clove, 'cloves': clove,
    'tranche': slice, 'tranches': slice, 'slices': slice,
    'botte': bunch, 'bottes': bunch, 'bunches': bunch,
    'brin': sprig, 'brins': sprig, 'tige': sprig, 'tiges': sprig, 'sprigs': sprig,
    'feuille': leaf, 'feuilles': leaf, 'leaves': leaf,
    'pincée': pinch, 'pincées': pinch,
    'boîte': can, 'boîtes': can, 'cans': can,
    'au goût': toTaste, 'to taste': toTaste,
  };
}
