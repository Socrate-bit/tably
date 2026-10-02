import 'package:equatable/equatable.dart';

/// The fixed set of units an ingredient can be measured in. Only the id is
/// persisted; the label comes from l10n. Weights and volumes carry their
/// size in a [base] unit so amounts can be summed across recipes.
enum IngredientUnit {
  g('g'),
  kg('kg', base: 'g', factor: 1000),
  ml('ml'),
  l('l', base: 'ml', factor: 1000),
  tbsp('tbsp', base: 'ml', factor: 15),
  tsp('tsp', base: 'ml', factor: 5),
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

  const IngredientUnit(this.id, {String? base, this.factor = 1}) : _base = base;
  final String id;
  final String? _base;

  /// How many [baseUnit] one of this unit is, e.g. 15 for a tablespoon.
  final double factor;

  /// The unit this one converts into: g for weights, ml for volumes, itself
  /// for anything counted.
  IngredientUnit get baseUnit => _base == null ? this : fromId(_base);

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

/// An amount in a unit, e.g. one part of a shopping-list line.
class Quantity extends Equatable {
  const Quantity(this.amount, this.unit);

  final double amount;
  final IngredientUnit unit;

  Map<String, dynamic> toMap() => {'amount': amount, 'unit': unit.id};

  factory Quantity.fromMap(Map<String, dynamic> map) =>
      Quantity((map['amount'] as num?)?.toDouble() ?? 0, IngredientUnit.fromId(map['unit'] as String?));

  @override
  List<Object?> get props => [amount, unit];
}
