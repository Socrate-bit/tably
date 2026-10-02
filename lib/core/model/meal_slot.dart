/// A meal of the day. Order matters: it is the order slots are listed in a day.
enum MealSlot {
  lunch('lunch', 12),
  dinner('dinner', 20);

  const MealSlot(this.id, this.hour);
  final String id;

  /// When the meal is eaten, in hours since midnight — how leftovers age.
  final int hour;

  /// The slots planned for [mealsPerDay]: dinner only, then lunch + dinner.
  static List<MealSlot> forMealsPerDay(int mealsPerDay) => mealsPerDay == 1 ? const [dinner] : const [lunch, dinner];
}
