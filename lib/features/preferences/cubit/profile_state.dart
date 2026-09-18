part of 'profile_cubit.dart';

enum ProfileStatus { loading, ready, missing, failed }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile = const UserProfile(),
    this.error,
  });

  final ProfileStatus status;
  final UserProfile profile;
  final Object? error;

  bool get isLoading => status == ProfileStatus.loading;

  /// True once the user has finished onboarding and has a stored profile.
  bool get hasOnboarded => status == ProfileStatus.ready && profile.onboardingComplete;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    Object? error,
    bool clearError = false,
  }) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, profile, error];
}
