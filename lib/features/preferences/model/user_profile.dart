import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/model/meal_slot.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/user_type.dart';
import '../../../core/model/weekday.dart';

/// Everything the planner needs about a user. Stored at `users/{uid}` and
/// streamed so any change reflects in the UI immediately.
class UserProfile extends Equatable {
  const UserProfile({
    this.name = '',
    this.household = 1,
    this.mealsPerDay = 1,
    this.variety = Variety.high,
    this.days = const {
      Weekday.monday,
      Weekday.tuesday,
      Weekday.wednesday,
      Weekday.thursday,
      Weekday.friday,
      Weekday.saturday,
      Weekday.sunday,
    },
    this.budget = 60,
    this.country = Country.france,
    this.store = Store.fallback,
    this.languageCode = 'fr',
    this.cravings = const {Craving.quick, Craving.highProtein},
    this.diets = const {Diet.none},
    this.allergies = const {Allergy.none},
    this.proteins = const {Protein.beef, Protein.pork, Protein.chicken},
    this.appliances = const {Appliance.microwave, Appliance.hob},
    this.customPreferences = const [],
    this.ageRange,
    this.goals = const {},
    this.blockers = const {},
    this.cookTime,
    this.onboardingComplete = false,
    this.weeklyReminder = false,
    this.userType = UserType.normal,
  });

  /// Household size bounds, matching the design's stepper.
  static const minHousehold = 1;
  static const maxHousehold = 12;

  /// Meals planned per cooking day: dinner, then lunch.
  static const maxMealsPerDay = 2;

  /// Bounds on the user's own free-text rules ("no coriander").
  static const maxCustomPreferences = 10;
  static const maxCustomPreferenceLength = 80;

  /// Longest a cooked dish is kept before it is eaten, in hours.
  static const leftoverHours = 72;

  final String name;
  final int household;
  final int mealsPerDay;
  final Variety variety;
  final Set<Weekday> days;
  final double budget;
  final Country country;
  final Store store;
  final String languageCode;
  final Set<Craving> cravings;
  final Set<Diet> diets;
  final Set<Allergy> allergies;
  final Set<Protein> proteins;
  final Set<Appliance> appliances;

  /// The user's own rules in their words ("no coriander", "kids hate
  /// spicy"), applied as strictly as allergies when recipes are checked.
  final List<String> customPreferences;

  /// Survey answers — captured once during onboarding for personalisation.
  final String? ageRange;
  final Set<String> goals;
  final Set<String> blockers;
  final String? cookTime;

  final bool onboardingComplete;
  final bool weeklyReminder;

  /// Paywall entitlement, granted by redeeming a referral code. Read-only here:
  /// [toMap] deliberately omits it so a client save can never change it, which
  /// is what the `users/{uid}` security rule relies on.
  final UserType userType;

  /// Days kept in calendar order, which is how the plan is rendered.
  List<Weekday> get orderedDays => Weekday.values.where(days.contains).toList();

  int get daysCount => days.length;

  /// Meals planned in the week.
  int get mealCount => days.length * mealsPerDay;

  /// Every meal of the week in eating order.
  List<(Weekday, MealSlot)> get meals => [
        for (final day in orderedDays)
          for (final slot in MealSlot.forMealsPerDay(mealsPerDay)) (day, slot),
      ];

  /// When each of [meals] is eaten, in hours since Monday midnight.
  List<int> get mealHours => [for (final (day, slot) in meals) day.index * 24 + slot.hour];

  /// The fewest dishes that keep every leftover fresh: one more each time a
  /// meal falls past [leftoverHours] after the last one started.
  int get minFreshRecipes {
    var count = 0;
    int? cookedAt;
    for (final hour in mealHours) {
      if (cookedAt == null || hour - cookedAt > leftoverHours) {
        count++;
        cookedAt = hour;
      }
    }
    return count;
  }

  /// Recipes to cook for [variety]: one per meal, per two meals, or per four —
  /// but never fewer than [minFreshRecipes], so no leftover is kept too long.
  int get recipesToCook => min(
        mealCount,
        max(
          minFreshRecipes,
          switch (variety) {
            Variety.high => mealCount,
            Variety.balanced => (mealCount + 1) ~/ 2,
            Variety.low => (mealCount + 3) ~/ 4,
          },
        ),
      );

  /// Dishes each variety level would cook this week. Levels that land on the
  /// same count as a higher one are dropped, so every choice differs.
  Map<Variety, int> get varietyRecipes {
    final counts = <Variety, int>{};
    for (final v in Variety.values) {
      final count = copyWith(variety: v).recipesToCook;
      if (!counts.containsValue(count)) counts[v] = count;
    }
    return counts;
  }

  /// The name to greet the user with, falling back to a generic chef.
  String displayName(String fallback) => name.trim().isEmpty ? fallback : name.trim();

  UserProfile copyWith({
    String? name,
    int? household,
    int? mealsPerDay,
    Variety? variety,
    Set<Weekday>? days,
    double? budget,
    Country? country,
    Store? store,
    String? languageCode,
    Set<Craving>? cravings,
    Set<Diet>? diets,
    Set<Allergy>? allergies,
    Set<Protein>? proteins,
    Set<Appliance>? appliances,
    List<String>? customPreferences,
    String? ageRange,
    Set<String>? goals,
    Set<String>? blockers,
    String? cookTime,
    bool? onboardingComplete,
    bool? weeklyReminder,
    UserType? userType,
  }) {
    return UserProfile(
      name: name ?? this.name,
      household: household ?? this.household,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      variety: variety ?? this.variety,
      days: days ?? this.days,
      budget: budget ?? this.budget,
      country: country ?? this.country,
      store: store ?? this.store,
      languageCode: languageCode ?? this.languageCode,
      cravings: cravings ?? this.cravings,
      diets: diets ?? this.diets,
      allergies: allergies ?? this.allergies,
      proteins: proteins ?? this.proteins,
      appliances: appliances ?? this.appliances,
      customPreferences: customPreferences ?? this.customPreferences,
      ageRange: ageRange ?? this.ageRange,
      goals: goals ?? this.goals,
      blockers: blockers ?? this.blockers,
      cookTime: cookTime ?? this.cookTime,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      weeklyReminder: weeklyReminder ?? this.weeklyReminder,
      userType: userType ?? this.userType,
    );
  }

  /// Note: `userType` is intentionally absent — it is server-owned, and the
  /// merge write leaves the stored value untouched.
  Map<String, dynamic> toMap() => {
        'name': name,
        'household': household,
        'mealsPerDay': mealsPerDay,
        'variety': variety.id,
        'days': orderedDays.map((d) => d.id).toList(),
        'budget': budget,
        'country': country.id,
        'store': store.id,
        'languageCode': languageCode,
        'cravings': cravings.map((c) => c.id).toList(),
        'diets': diets.map((d) => d.id).toList(),
        'allergies': allergies.map((a) => a.id).toList(),
        'proteins': proteins.map((p) => p.id).toList(),
        'appliances': appliances.map((a) => a.id).toList(),
        'customPreferences': customPreferences,
        'ageRange': ageRange,
        'goals': goals.toList(),
        'blockers': blockers.toList(),
        'cookTime': cookTime,
        'onboardingComplete': onboardingComplete,
        'weeklyReminder': weeklyReminder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    /// A missing key falls back; an empty list does too unless [allowEmpty],
    /// for the choices a user may leave blank.
    Set<T> parse<T extends Enum>(
      String key,
      List<T> values,
      String Function(T) id,
      Set<T> fallback, {
      bool allowEmpty = false,
    }) {
      final raw = map[key];
      if (raw is! List) return fallback;
      final parsed = raw
          .whereType<String>()
          .map((s) => values.where((v) => id(v) == s).firstOrNull)
          .whereType<T>()
          .toSet();
      return parsed.isEmpty && !(allowEmpty && raw.isEmpty) ? fallback : parsed;
    }

    Set<String> strings(String key) => (map[key] as List? ?? const []).whereType<String>().toSet();

    const fallback = UserProfile();
    final mealsPerDay = ((map['mealsPerDay'] as num?)?.toInt() ?? fallback.mealsPerDay).clamp(1, maxMealsPerDay);
    return UserProfile(
      name: map['name'] as String? ?? fallback.name,
      household: ((map['household'] as num?)?.toInt() ?? fallback.household).clamp(minHousehold, maxHousehold),
      mealsPerDay: mealsPerDay,
      // Profiles saved before this setting existed reused dishes only with two meals a day.
      variety: Variety.values.where((v) => v.id == map['variety']).firstOrNull ??
          (mealsPerDay == 1 ? Variety.high : Variety.balanced),
      days: parse('days', Weekday.values, (d) => d.id, fallback.days),
      budget: (map['budget'] as num?)?.toDouble() ?? fallback.budget,
      country: Country.fromId(map['country'] as String? ?? fallback.country.id),
      store: Store.fromId(map['store'] as String?),
      languageCode: map['languageCode'] as String? ?? fallback.languageCode,
      cravings: parse('cravings', Craving.values, (c) => c.id, fallback.cravings, allowEmpty: true),
      diets: parse('diets', Diet.values, (d) => d.id, fallback.diets),
      allergies: parse('allergies', Allergy.values, (a) => a.id, fallback.allergies),
      proteins: parse('proteins', Protein.values, (p) => p.id, fallback.proteins, allowEmpty: true),
      appliances: parse('appliances', Appliance.values, (a) => a.id, fallback.appliances, allowEmpty: true),
      customPreferences: (map['customPreferences'] as List? ?? const []).whereType<String>().toList(),
      ageRange: map['ageRange'] as String?,
      goals: strings('goals'),
      blockers: strings('blockers'),
      cookTime: map['cookTime'] as String?,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      weeklyReminder: map['weeklyReminder'] as bool? ?? false,
      userType: UserType.fromId(map['userType'] as String?),
    );
  }

  @override
  List<Object?> get props => [
        name,
        household,
        mealsPerDay,
        variety,
        days,
        budget,
        country,
        store,
        languageCode,
        cravings,
        diets,
        allergies,
        proteins,
        appliances,
        customPreferences,
        ageRange,
        goals,
        blockers,
        cookTime,
        onboardingComplete,
        weeklyReminder,
        userType,
      ];
}
