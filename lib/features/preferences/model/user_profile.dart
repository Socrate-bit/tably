import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';

/// Everything the planner needs about a user. Stored at `users/{uid}` and
/// streamed so any change reflects in the UI immediately.
class UserProfile extends Equatable {
  const UserProfile({
    this.name = '',
    this.household = 1,
    this.mealsPerDay = 1,
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
    this.ageRange,
    this.goals = const {},
    this.blockers = const {},
    this.cookTime,
    this.onboardingComplete = false,
    this.weeklyReminder = false,
  });

  /// Household size bounds, matching the design's stepper.
  static const minHousehold = 1;
  static const maxHousehold = 12;

  /// Meals planned per cooking day: dinner, then lunch, then breakfast.
  static const maxMealsPerDay = 3;

  final String name;
  final int household;
  final int mealsPerDay;
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

  /// Survey answers — captured once during onboarding for personalisation.
  final String? ageRange;
  final Set<String> goals;
  final Set<String> blockers;
  final String? cookTime;

  final bool onboardingComplete;
  final bool weeklyReminder;

  /// Days kept in calendar order, which is how the plan is rendered.
  List<Weekday> get orderedDays => Weekday.values.where(days.contains).toList();

  int get daysCount => days.length;

  /// The name to greet the user with, falling back to a generic chef.
  String displayName(String fallback) => name.trim().isEmpty ? fallback : name.trim();

  UserProfile copyWith({
    String? name,
    int? household,
    int? mealsPerDay,
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
    String? ageRange,
    Set<String>? goals,
    Set<String>? blockers,
    String? cookTime,
    bool? onboardingComplete,
    bool? weeklyReminder,
  }) {
    return UserProfile(
      name: name ?? this.name,
      household: household ?? this.household,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
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
      ageRange: ageRange ?? this.ageRange,
      goals: goals ?? this.goals,
      blockers: blockers ?? this.blockers,
      cookTime: cookTime ?? this.cookTime,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      weeklyReminder: weeklyReminder ?? this.weeklyReminder,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'household': household,
        'mealsPerDay': mealsPerDay,
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
        'ageRange': ageRange,
        'goals': goals.toList(),
        'blockers': blockers.toList(),
        'cookTime': cookTime,
        'onboardingComplete': onboardingComplete,
        'weeklyReminder': weeklyReminder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    Set<T> parse<T extends Enum>(String key, List<T> values, String Function(T) id, Set<T> fallback) {
      final raw = map[key];
      if (raw is! List) return fallback;
      final parsed = raw
          .whereType<String>()
          .map((s) => values.where((v) => id(v) == s).firstOrNull)
          .whereType<T>()
          .toSet();
      return parsed.isEmpty ? fallback : parsed;
    }

    Set<String> strings(String key) => (map[key] as List? ?? const []).whereType<String>().toSet();

    const fallback = UserProfile();
    return UserProfile(
      name: map['name'] as String? ?? fallback.name,
      household: ((map['household'] as num?)?.toInt() ?? fallback.household).clamp(minHousehold, maxHousehold),
      mealsPerDay: ((map['mealsPerDay'] as num?)?.toInt() ?? fallback.mealsPerDay).clamp(1, maxMealsPerDay),
      days: parse('days', Weekday.values, (d) => d.id, fallback.days),
      budget: (map['budget'] as num?)?.toDouble() ?? fallback.budget,
      country: Country.fromId(map['country'] as String? ?? fallback.country.id),
      store: Store.fromId(map['store'] as String?),
      languageCode: map['languageCode'] as String? ?? fallback.languageCode,
      cravings: parse('cravings', Craving.values, (c) => c.id, fallback.cravings),
      diets: parse('diets', Diet.values, (d) => d.id, fallback.diets),
      allergies: parse('allergies', Allergy.values, (a) => a.id, fallback.allergies),
      proteins: parse('proteins', Protein.values, (p) => p.id, fallback.proteins),
      appliances: parse('appliances', Appliance.values, (a) => a.id, fallback.appliances),
      ageRange: map['ageRange'] as String?,
      goals: strings('goals'),
      blockers: strings('blockers'),
      cookTime: map['cookTime'] as String?,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      weeklyReminder: map['weeklyReminder'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        name,
        household,
        mealsPerDay,
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
        ageRange,
        goals,
        blockers,
        cookTime,
        onboardingComplete,
        weeklyReminder,
      ];
}
