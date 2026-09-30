/// Supermarkets offered in the design, cheapest first. [priceFactor] scales a
/// recipe's reference price (E.Leclerc, updated 2026-09) to what it costs at
/// that store.
enum Store {
  lidl('lidl', 'Lidl', 0.975),
  leclerc('leclerc', 'E.Leclerc', 1.00),
  aldi('aldi', 'Aldi', 1.02),
  intermarche('intermarche', 'Intermarché', 1.04),
  superU('superu', 'Super U', 1.05),
  carrefour('carrefour', 'Carrefour', 1.07),
  auchan('auchan', 'Auchan', 1.10),
  monoprix('monoprix', 'Monoprix', 1.15),
  franprix('franprix', 'Franprix', 1.25);

  const Store(this.id, this.displayName, this.priceFactor);

  final String id;

  /// The brand name, shown as-is in every language.
  final String displayName;
  final double priceFactor;

  String get logoAsset => 'assets/stores/$id.jpg';

  static const fallback = Store.lidl;

  /// Accepts the id or, for profiles saved before ids existed, the brand name.
  static Store fromId(String? value) {
    final key = value?.trim().toLowerCase();
    return Store.values.firstWhere(
      (s) => s.id == key || s.displayName.toLowerCase() == key,
      orElse: () => fallback,
    );
  }

  /// The cheapest other store, offered as a switch after onboarding.
  Store get cheapestAlternative => Store.values
      .where((s) => s != this)
      .reduce((a, b) => b.priceFactor < a.priceFactor ? b : a);
}
