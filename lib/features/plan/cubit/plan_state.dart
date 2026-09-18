part of 'plan_cubit.dart';

enum PlanStatus { loading, ready, failed }

class PlanState extends Equatable {
  const PlanState({
    this.status = PlanStatus.loading,
    this.meals = const [],
    this.generating = false,
    this.error,
  });

  final PlanStatus status;
  final List<PlannedMeal> meals;

  /// True while a regenerate is in flight.
  final bool generating;
  final Object? error;

  /// Total cost of the week for the whole household.
  double totalCost(int household) =>
      meals.fold<double>(0, (sum, m) => sum + m.price) * household;

  PlanState copyWith({
    PlanStatus? status,
    List<PlannedMeal>? meals,
    bool? generating,
    Object? error,
    bool clearError = false,
  }) =>
      PlanState(
        status: status ?? this.status,
        meals: meals ?? this.meals,
        generating: generating ?? this.generating,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, meals, generating, error];
}
