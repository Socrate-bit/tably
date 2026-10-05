import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';
import '../../preferences/model/user_profile.dart';
import 'recipe.dart';

/// The hard constraints a recipe search respects: diets, allergies, the meats
/// eaten, the appliances in the kitchen and the longest cooking time. They start from
/// the profile, and the filters screen can change them for searching without
/// touching the profile.
class DietaryConstraints extends Equatable {
  const DietaryConstraints({
    this.diets = const {Diet.none},
    this.allergies = const {Allergy.none},
    this.proteins = Protein.meats,
    this.appliances = const {Appliance.microwave, Appliance.hob},
    this.cookMinutes = UserProfile.cookMinutesCeiling,
  });

  factory DietaryConstraints.of(UserProfile profile) => DietaryConstraints(
        diets: profile.diets,
        allergies: profile.allergies,
        proteins: profile.proteins,
        appliances: profile.appliances,
        cookMinutes: profile.cookMinutes,
      );

  final Set<Diet> diets;
  final Set<Allergy> allergies;

  /// As in the preferences: nothing ticked means any meat, "no meat" none.
  final Set<Protein> proteins;
  final Set<Appliance> appliances;

  /// Longest a recipe may take, in minutes; the ceiling is no limit.
  final int cookMinutes;

  bool get hasCookLimit => cookMinutes < UserProfile.cookMinutesCeiling;

  /// Whether a dish whose main protein is [protein] fits the meats picked.
  /// Meat-free dishes always do; diets rule them out elsewhere.
  bool allows(RecipeProtein protein) => switch (protein) {
        RecipeProtein.vegetarian || RecipeProtein.tofu => true,
        _ => proteins.isEmpty || proteins.any((p) => p.id == protein.id),
      };

  /// [profile] with these constraints in place of its own, so the search and
  /// the Gemini check apply them.
  UserProfile applyTo(UserProfile profile) =>
      profile.copyWith(
        diets: diets,
        allergies: allergies,
        proteins: proteins,
        appliances: appliances,
        cookMinutes: cookMinutes,
      );

  /// How many options differ from [other], counted per option like the
  /// filter badge counts chips.
  int differencesFrom(DietaryConstraints other) {
    int diff<T>(Set<T> a, Set<T> b) => a.difference(b).length + b.difference(a).length;
    // No meat ticked means the same as every meat.
    Set<Protein> meats(Set<Protein> picked) => picked.isEmpty ? Protein.meats : picked;
    return diff(diets, other.diets) +
        diff(allergies, other.allergies) +
        diff(meats(proteins), meats(other.proteins)) +
        diff(appliances, other.appliances) +
        (cookMinutes != other.cookMinutes ? 1 : 0);
  }

  DietaryConstraints copyWith({
    Set<Diet>? diets,
    Set<Allergy>? allergies,
    Set<Protein>? proteins,
    Set<Appliance>? appliances,
    int? cookMinutes,
  }) =>
      DietaryConstraints(
        diets: diets ?? this.diets,
        allergies: allergies ?? this.allergies,
        proteins: proteins ?? this.proteins,
        appliances: appliances ?? this.appliances,
        cookMinutes: cookMinutes ?? this.cookMinutes,
      );

  @override
  List<Object?> get props => [diets, allergies, proteins, appliances, cookMinutes];
}
