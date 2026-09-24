/// Supermarkets offered in the design, cheapest first. [priceFactor] scales a
/// recipe's reference price to what it costs at that store.
enum Store {
  lidl('lidl', 'Lidl', 0.88),
  aldi('aldi', 'Aldi', 0.90),
  leclerc('leclerc', 'E.Leclerc', 0.94),
  intermarche('intermarche', 'Intermarché', 0.97),
  carrefour('carrefour', 'Carrefour', 1.00),
  auchan('auchan', 'Auchan', 1.02),
  superU('superu', 'Super U', 1.05),
  franprix('franprix', 'Franprix', 1.14),
  monoprix('monoprix', 'Monoprix', 1.21);

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
