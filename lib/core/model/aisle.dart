/// The shopping-list aisles, in the order the list prints them. Only the id is
/// persisted; the label comes from l10n.
enum Aisle {
  produce('produce'),
  meatFish('meat_fish'),
  pastaRice('pasta_rice'),
  tinsSauces('tins_sauces'),
  herbsGrocery('herbs_grocery');

  const Aisle(this.id);
  final String id;

  /// Anything unrecognised lands in the catch-all grocery aisle.
  static Aisle fromId(String? id) =>
      values.firstWhere((a) => a.id == id, orElse: () => herbsGrocery);
}
