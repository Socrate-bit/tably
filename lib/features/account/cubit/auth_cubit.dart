import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../service/auth_service.dart';

part 'auth_state.dart';

/// Keeps the app's notion of "who am I" in sync with Firebase Auth.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthService authService, required AnalyticsService analytics})
      : _auth = authService,
        _analytics = analytics,
        super(const AuthState()) {
    _subscription = _auth.userChanges.listen(_onUserChanged, onError: (Object e) {
      debugPrint('[AuthCubit] userChanges error: $e');
    });
  }

  final AuthService _auth;
  final AnalyticsService _analytics;
  late final StreamSubscription<User?> _subscription;

  /// Signs in anonymously so a profile can be created before the user commits
  /// to an account.
  Future<void> start() async {
    try {
      await _auth.ensureSignedIn();
    } catch (e) {
      debugPrint('[AuthCubit] start failed: $e');
      emit(state.copyWith(status: AuthStatus.failed, error: e));
    }
  }

  void _onUserChanged(User? user) {
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unknown));
      unawaited(start());
      return;
    }
    final signedIn = !user.isAnonymous;
    emit(state.copyWith(
      status: signedIn ? AuthStatus.signedIn : AuthStatus.anonymous,
      uid: user.uid,
      displayName: user.displayName,
      busy: false,
      clearError: true,
    ));
    unawaited(_analytics.identify(user.uid, properties: {'signed_in': signedIn}));
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(busy: true, clearError: true));
    unawaited(_analytics.capture(AnalyticsEvents.signInStarted));
    try {
      await _auth.signInWithApple();
      unawaited(_analytics.capture(AnalyticsEvents.signInCompleted));
    } catch (e) {
      debugPrint('[AuthCubit] signInWithApple failed: $e');
      emit(state.copyWith(busy: false, error: e));
    }
  }

  Future<void> signOut() async {
    try {
      await _analytics.reset();
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthCubit] signOut failed: $e');
      emit(state.copyWith(error: e));
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.deleteAccount();
    } catch (e) {
      debugPrint('[AuthCubit] deleteAccount failed: $e');
      emit(state.copyWith(error: e));
    }
  }

  /// Clears a surfaced error once the UI has shown it.
  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
