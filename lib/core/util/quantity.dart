import '../../l10n/app_localizations.dart';
import '../model/ingredient_unit.dart';
import 'option_labels.dart';

/// Formats an ingredient amount with its unit: "150g", "½", "2 gousses".
/// Grams and millilitres are whole numbers; other amounts use common fractions.
String formatQuantity(double amount, IngredientUnit unit, AppL10n l10n) {
  final label = l10n.unitLabel(unit, amount);
  if (amount <= 0 || unit == IngredientUnit.toTaste) return label;
  // Grams and millilitres round to whole numbers; kilos and litres keep
  // fractions ("1½kg").
  final whole = unit == IngredientUnit.g || unit == IngredientUnit.ml;
  final number = whole ? _whole(amount) : _count(amount);
  if (label.isEmpty) return number;
  return unit.isMetric ? '$number$label' : '$number $label';
}

String _whole(double amount) => amount < 1 ? _count(amount) : '${amount.round()}';

/// Whole numbers stay whole; otherwise the nearest quarter or third as a
/// glyph, else one decimal. A pinch never rounds down to "0".
String _count(double amount) {
  final whole = amount.floor();
  final rest = amount - whole;
  if (whole == 0 && rest < 0.19) return '⅛';
  if (rest < 0.08) return '$whole';
  if (rest > 0.92) return '${whole + 1}';
  const fractions = [(0.25, '¼'), (0.33, '⅓'), (0.5, '½'), (0.67, '⅔'), (0.75, '¾')];
  for (final (value, glyph) in fractions) {
    if ((rest - value).abs() < 0.05) return whole == 0 ? glyph : '$whole$glyph';
  }
  return amount.toStringAsFixed(1);
}
