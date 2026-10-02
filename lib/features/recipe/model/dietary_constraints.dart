import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';
import '../../preferences/model/user_profile.dart';

/// The hard constraints a recipe search respects: diets, allergies and the
/// appliances in the kitchen. They start from the profile, and the filters
/// screen can change them for searching without touching the profile.
class DietaryConstraints extends Equatable {
  const DietaryConstraints({
    this.diets = const {Diet.none},
    this.allergies = const {Allergy.none},
    this.appliances = const {Appliance.microwave, Appliance.hob},
  });

  factory DietaryConstraints.of(UserProfile profile) =>
      DietaryConstraints(diets: profile.diets, allergies: profile.allergies, appliances: profile.appliances);

  final Set<Diet> diets;
  final Set<Allergy> allergies;
  final Set<Appliance> appliances;

  /// [profile] with these constraints in place of its own, so the search and
  /// the Gemini check apply them.
  UserProfile applyTo(UserProfile profile) =>
      profile.copyWith(diets: diets, allergies: allergies, appliances: appliances);

  /// How many options differ from [other], counted per option like the
  /// filter badge counts chips.
  int differencesFrom(DietaryConstraints other) {
    int diff<T>(Set<T> a, Set<T> b) => a.difference(b).length + b.difference(a).length;
    return diff(diets, other.diets) + diff(allergies, other.allergies) + diff(appliances, other.appliances);
  }

  DietaryConstraints copyWith({Set<Diet>? diets, Set<Allergy>? allergies, Set<Appliance>? appliances}) =>
      DietaryConstraints(
        diets: diets ?? this.diets,
        allergies: allergies ?? this.allergies,
        appliances: appliances ?? this.appliances,
      );

  @override
  List<Object?> get props => [diets, allergies, appliances];
}
