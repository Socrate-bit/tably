/// Formats an ingredient amount with its unit: "150g", "½", "2 gousses".
/// Weights and volumes are whole numbers; small counts use common fractions.
String formatQuantity(double amount, String unit) {
  if (amount <= 0) return unit;
  final number = _metric.contains(unit.toLowerCase()) ? _whole(amount) : _count(amount);
  if (unit.isEmpty) return number;
  return _metric.contains(unit.toLowerCase()) ? '$number$unit' : '$number $unit';
}

/// Units written glued to the number, as the design does ("150g", "15ml").
const _metric = {'g', 'kg', 'ml', 'l', 'cl'};

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
