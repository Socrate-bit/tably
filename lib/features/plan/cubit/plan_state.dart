part of 'plan_cubit.dart';

enum PlanStatus { loading, ready, failed }

class PlanState extends Equatable {
  const PlanState({
    this.status = PlanStatus.loading,
    this.settings = const PlanSettings(),
    this.week = const WeekPlan(),
    this.regenerating = false,
    this.error,
  });

  final PlanStatus status;
  final PlanSettings settings;

  /// The week derived from the profile and [settings].
  final WeekPlan week;

  /// True while "régénérer le plan" spins, before the new week lands.
  final bool regenerating;
  final Object? error;

  PlanState copyWith({
    PlanStatus? status,
    PlanSettings? settings,
    WeekPlan? week,
    bool? regenerating,
    Object? error,
    bool clearError = false,
  }) =>
      PlanState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        week: week ?? this.week,
        regenerating: regenerating ?? this.regenerating,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, settings, week, regenerating, error];
}
