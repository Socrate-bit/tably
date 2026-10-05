/// Stable identifiers for every multiple-choice option in onboarding and
/// preferences. Only the id is persisted; the label comes from l10n.
abstract final class OptionIds {
  static const none = 'none';
}

/// How many different recipes the week is planned with; the rest are leftovers.
enum Variety {
  high('high', '🌈'),
  balanced('balanced', '⚖️'),
  low('low', '🍲');

  const Variety(this.id, this.icon);
  final String id;
  final String icon;
}

enum Craving {
  quick('quick', '⚡'),
  highProtein('high_protein', '💪'),
  lowCalorie('low_calorie', '⚖️'),
  familyFavourites('family_favourites', '👨‍👩‍👧'),
  healthyComfort('healthy_comfort', '🧺'),
  fakeaway('fakeaway', '🥡'),
  easyDigestion('easy_digestion', '🧍'),
  indulgent('indulgent', '🤤');

  const Craving(this.id, this.icon);
  final String id;
  final String icon;
}

enum Diet {
  none(OptionIds.none, '🚫'),
  vegetarian('vegetarian', '🥕'),
  vegan('vegan', '🌱'),
  pescatarian('pescatarian', '🐟'),
  halal('halal', '🌙');

  const Diet(this.id, this.icon);
  final String id;
  final String icon;
}

enum Allergy {
  none(OptionIds.none, '🚫'),
  glutenFree('gluten_free', '🌾'),
  lactoseFree('lactose_free', '🥛'),
  nutFree('nut_free', '🥜'),
  eggFree('egg_free', '🥚'),
  shellfishFree('shellfish_free', '🦐'),
  sesameFree('sesame_free', '🫓'),
  soyFree('soy_free', '🫘');

  const Allergy(this.id, this.icon);
  final String id;
  final String icon;
}

enum Protein {
  beef('beef', '🥩'),
  pork('pork', '🥓'),
  chicken('chicken', '🍗'),
  fish('fish', '🐟'),

  /// Exclusive: eats no meat or fish. Ticking nothing means no preference.
  noMeat('no_meat', '🥦');

  const Protein(this.id, this.icon);
  final String id;
  final String icon;

  /// Every meat and fish: ticking them all is the most permissive choice.
  static const meats = {beef, pork, chicken, fish};
}

enum Appliance {
  microwave('microwave', '📺'),
  hob('hob', '🔥'),
  oven('oven', '🔲'),
  airFryer('air_fryer', '🍟'),
  mixer('mixer', '🥤'),
  slowCooker('slow_cooker', '🍲'),
  pressureCooker('pressure_cooker', '🥘'),
  barbecue('barbecue', '🍖');

  const Appliance(this.id, this.icon);
  final String id;
  final String icon;
}

/// Country drives currency and the store list offered during onboarding.
enum Country {
  unitedStates('united_states', '🇺🇸', 'USD', r'$'),
  europe('europe', '🇪🇺', 'EUR', '€'),
  unitedKingdom('united_kingdom', '🇬🇧', 'GBP', '£'),
  australia('australia', '🇦🇺', 'AUD', r'$'),
  canada('canada', '🇨🇦', 'CAD', r'$'),
  newZealand('new_zealand', '🇳🇿', 'NZD', r'$'),
  brazil('brazil', '🇧🇷', 'BRL', r'R$'),
  germany('germany', '🇩🇪', 'EUR', '€'),
  ireland('ireland', '🇮🇪', 'EUR', '€'),
  sweden('sweden', '🇸🇪', 'SEK', 'kr'),
  netherlands('netherlands', '🇳🇱', 'EUR', '€'),
  france('france', '🇫🇷', 'EUR', '€'),
  spain('spain', '🇪🇸', 'EUR', '€'),
  restOfEurope('rest_of_europe', '🇪🇺', 'EUR', '€');

  const Country(this.id, this.flag, this.currencyCode, this.currencySymbol);
  final String id;
  final String flag;
  final String currencyCode;
  final String currencySymbol;

  static Country fromId(String id) =>
      Country.values.firstWhere((c) => c.id == id, orElse: () => Country.france);
}
