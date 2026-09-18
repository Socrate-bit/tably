part of 'auth_cubit.dart';

enum AuthStatus { unknown, anonymous, signedIn, failed }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.uid,
    this.displayName,
    this.busy = false,
    this.error,
  });

  final AuthStatus status;
  final String? uid;
  final String? displayName;

  /// True while an interactive sign-in is running.
  final bool busy;

  /// Set when sign-in failed; the UI shows it once, then it is cleared.
  final Object? error;

  bool get isReady => uid != null;
  bool get isSignedIn => status == AuthStatus.signedIn;

  AuthState copyWith({
    AuthStatus? status,
    String? uid,
    String? displayName,
    bool? busy,
    Object? error,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, uid, displayName, busy, error];
}
