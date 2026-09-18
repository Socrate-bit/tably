import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/weekday.dart';

/// Everything the planner needs about a user. Stored at `users/{uid}` and
/// streamed so any change reflects in the UI immediately.
class UserProfile extends Equatable {
  const UserProfile({
    this.name = '',
    this.household = 1,
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
    this.store = Stores.defaultStore,
    this.languageCode = 'fr',
    this.cravings = const {Craving.quick, Craving.highProtein},
    this.diets = const {Diet.none},
    this.allergies = const {Allergy.none},
    this.proteins = const {Protein.beef, Protein.pork, Protein.chicken},
    this.appliances = const {Appliance.microwave, Appliance.hob},
    this.ageRange,
    this.goal,
    this.blocker,
    this.savingsBelief,
    this.cookTime,
    this.discoverySource,
    this.onboardingComplete = false,
    this.weeklyReminder = false,
  });

  final String name;
  final int household;
  final Set<Weekday> days;
  final double budget;
  final Country country;
  final String store;
  final String languageCode;
  final Set<Craving> cravings;
  final Set<Diet> diets;
  final Set<Allergy> allergies;
  final Set<Protein> proteins;
  final Set<Appliance> appliances;

  /// Survey answers — captured once during onboarding for personalisation.
  final String? ageRange;
  final String? goal;
  final String? blocker;
  final String? savingsBelief;
  final String? cookTime;
  final String? discoverySource;

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
    Set<Weekday>? days,
    double? budget,
    Country? country,
    String? store,
    String? languageCode,
    Set<Craving>? cravings,
    Set<Diet>? diets,
    Set<Allergy>? allergies,
    Set<Protein>? proteins,
    Set<Appliance>? appliances,
    String? ageRange,
    String? goal,
    String? blocker,
    String? savingsBelief,
    String? cookTime,
    String? discoverySource,
    bool? onboardingComplete,
    bool? weeklyReminder,
  }) {
    return UserProfile(
      name: name ?? this.name,
      household: household ?? this.household,
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
      goal: goal ?? this.goal,
      blocker: blocker ?? this.blocker,
      savingsBelief: savingsBelief ?? this.savingsBelief,
      cookTime: cookTime ?? this.cookTime,
      discoverySource: discoverySource ?? this.discoverySource,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      weeklyReminder: weeklyReminder ?? this.weeklyReminder,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'household': household,
        'days': orderedDays.map((d) => d.id).toList(),
        'budget': budget,
        'country': country.id,
        'store': store,
        'languageCode': languageCode,
        'cravings': cravings.map((c) => c.id).toList(),
        'diets': diets.map((d) => d.id).toList(),
        'allergies': allergies.map((a) => a.id).toList(),
        'proteins': proteins.map((p) => p.id).toList(),
        'appliances': appliances.map((a) => a.id).toList(),
        'ageRange': ageRange,
        'goal': goal,
        'blocker': blocker,
        'savingsBelief': savingsBelief,
        'cookTime': cookTime,
        'discoverySource': discoverySource,
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

    const fallback = UserProfile();
    return UserProfile(
      name: map['name'] as String? ?? fallback.name,
      household: (map['household'] as num?)?.toInt() ?? fallback.household,
      days: parse('days', Weekday.values, (d) => d.id, fallback.days),
      budget: (map['budget'] as num?)?.toDouble() ?? fallback.budget,
      country: Country.fromId(map['country'] as String? ?? fallback.country.id),
      store: map['store'] as String? ?? fallback.store,
      languageCode: map['languageCode'] as String? ?? fallback.languageCode,
      cravings: parse('cravings', Craving.values, (c) => c.id, fallback.cravings),
      diets: parse('diets', Diet.values, (d) => d.id, fallback.diets),
      allergies: parse('allergies', Allergy.values, (a) => a.id, fallback.allergies),
      proteins: parse('proteins', Protein.values, (p) => p.id, fallback.proteins),
      appliances: parse('appliances', Appliance.values, (a) => a.id, fallback.appliances),
      ageRange: map['ageRange'] as String?,
      goal: map['goal'] as String?,
      blocker: map['blocker'] as String?,
      savingsBelief: map['savingsBelief'] as String?,
      cookTime: map['cookTime'] as String?,
      discoverySource: map['discoverySource'] as String?,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      weeklyReminder: map['weeklyReminder'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        name,
        household,
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
        goal,
        blocker,
        savingsBelief,
        cookTime,
        discoverySource,
        onboardingComplete,
        weeklyReminder,
      ];
}
