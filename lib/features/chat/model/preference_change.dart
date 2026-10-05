import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../preferences/model/user_profile.dart';

/// A preferences change the AI chef asked for, checked against the same
/// rules as the preferences screen. Lists are set whole, not toggled.
class PreferenceChange {
  const PreferenceChange._({required this.next, required this.changes, this.error});

  /// The profile once applied.
  final UserProfile next;

  /// What changes, by field: `{from, to}` for a value, `{added, removed}`
  /// for a list. Option ids, so the card can show them in any language.
  final Map<String, Object?> changes;

  /// Why the change is refused, for the model to fix; null when valid.
  final String? error;

  /// Applies [args] (a set_preferences call) to [current].
  static PreferenceChange of(UserProfile current, Map<String, Object?> args) {
    try {
      final next = _apply(current, args);
      return PreferenceChange._(next: next, changes: _diff(current, next));
    } on FormatException catch (e) {
      return PreferenceChange._(next: current, changes: const {}, error: e.message);
    }
  }

  static UserProfile _apply(UserProfile p, Map<String, Object?> args) {
    Set<T>? pick<T extends Enum>(String key, List<T> values, String Function(T) id) {
      final raw = args[key];
      if (raw == null) return null;
      if (raw is! List) throw FormatException('$key must be a list');
      final picked = <T>{};
      for (final value in raw) {
        final match = values.where((v) => id(v) == value).firstOrNull;
        if (match == null) throw FormatException('$key: unknown value "$value"');
        picked.add(match);
      }
      return picked;
    }

    T? one<T extends Enum>(String key, List<T> values, String Function(T) id) {
      final raw = args[key];
      if (raw == null) return null;
      return values.where((v) => id(v) == raw).firstOrNull ?? (throw FormatException('$key: unknown value "$raw"'));
    }

    int? whole(String key, int min, int max) {
      final raw = (args[key] as num?)?.round();
      if (raw != null && (raw < min || raw > max)) throw FormatException('$key must be between $min and $max');
      return raw;
    }

    // "None" stands alone and fills an empty choice, as on the screen.
    Set<T>? withNone<T>(Set<T>? picked, T none) {
      if (picked == null) return null;
      final rest = picked.where((v) => v != none).toSet();
      return rest.isEmpty ? {none} : rest;
    }

    final days = pick('days', Weekday.values, (d) => d.id);
    if (days != null && days.isEmpty) throw const FormatException('days: at least one cooking day is needed');
    final cravings = pick('cravings', Craving.values, (c) => c.id);
    if (cravings != null && cravings.length > 3) throw const FormatException('cravings: three at most');
    final proteins = pick('proteins', Protein.values, (p) => p.id);
    if (proteins != null && proteins.contains(Protein.noMeat) && proteins.length > 1) {
      throw const FormatException('proteins: no_meat cannot be combined with a meat');
    }
    final budget = (args['budget'] as num?)?.toDouble();
    if (budget != null && (budget < OnboardingCubit.minBudget || budget > OnboardingCubit.maxBudget)) {
      throw FormatException('budget must be between ${OnboardingCubit.minBudget} and ${OnboardingCubit.maxBudget}');
    }
    final language = args['language'] as String?;
    if (language != null && !AppL10n.supportedLocales.any((l) => l.languageCode == language)) {
      throw FormatException('language: unsupported "$language"');
    }
    final store = args['store'] as String?;
    if (store != null && !Store.values.any((s) => s.id == store)) throw FormatException('store: unknown "$store"');

    return p.copyWith(
      name: (args['name'] as String?)?.trim(),
      household: whole('household', UserProfile.minHousehold, UserProfile.maxHousehold),
      mealsPerDay: whole('meals_per_day', 1, UserProfile.maxMealsPerDay),
      variety: one('variety', Variety.values, (v) => v.id),
      days: days,
      budget: budget,
      store: store == null ? null : Store.fromId(store),
      languageCode: language,
      cravings: cravings,
      diets: withNone(pick('diets', Diet.values, (d) => d.id), Diet.none),
      allergies: withNone(pick('allergies', Allergy.values, (a) => a.id), Allergy.none),
      proteins: proteins,
      appliances: pick('appliances', Appliance.values, (a) => a.id),
      // The slider's ceiling means no limit.
      cookMinutes: whole('cook_minutes', UserProfile.cookMinutesFloor, UserProfile.cookMinutesCeiling),
    );
  }

  static Map<String, Object?> _diff(UserProfile from, UserProfile to) {
    final changes = <String, Object?>{};
    void value(String field, Object? before, Object? after) {
      if (before != after) changes[field] = {'from': before, 'to': after};
    }

    void list(String field, Iterable<String> before, Iterable<String> after) {
      final added = [
        for (final v in after)
          if (!before.contains(v)) v,
      ];
      final removed = [
        for (final v in before)
          if (!after.contains(v)) v,
      ];
      if (added.isNotEmpty || removed.isNotEmpty) changes[field] = {'added': added, 'removed': removed};
    }

    value('name', from.name, to.name);
    value('household', from.household, to.household);
    value('meals_per_day', from.mealsPerDay, to.mealsPerDay);
    value('variety', from.variety.id, to.variety.id);
    list('days', from.orderedDays.map((d) => d.id), to.orderedDays.map((d) => d.id));
    value('budget', from.budget, to.budget);
    value('store', from.store.id, to.store.id);
    value('language', from.languageCode, to.languageCode);
    list('cravings', from.cravings.map((c) => c.id), to.cravings.map((c) => c.id));
    list('diets', from.diets.map((d) => d.id), to.diets.map((d) => d.id));
    list('allergies', from.allergies.map((a) => a.id), to.allergies.map((a) => a.id));
    list('proteins', from.proteins.map((p) => p.id), to.proteins.map((p) => p.id));
    list('appliances', from.appliances.map((a) => a.id), to.appliances.map((a) => a.id));
    value('cook_minutes', from.cookMinutes, to.cookMinutes);
    return changes;
  }
}
