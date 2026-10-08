import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/analytics/analytics_service.dart';
import '../service/auth_service.dart';

part 'auth_state.dart';

/// Keeps the app's notion of "who am I" in sync with Firebase Auth.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthService authService, required AnalyticsService analytics})
    : _auth = authService,
      _analytics = analytics,
      super(const AuthState()) {
    _subscription = _auth.userChanges.listen(
      _onUserChanged,
      onError: (Object e, StackTrace s) {
        AnalyticsService.reportError('AuthCubit', 'userChanges', e, stack: s);
      },
    );
  }

  final AuthService _auth;
  final AnalyticsService _analytics;
  late final StreamSubscription<User?> _subscription;

  /// Guards against two sign-ins racing: the constructor starts one, and the
  /// initial null from [userChanges] would otherwise start a second.
  bool _signingIn = false;

  /// True once a user has been seen, so a later null means a real sign-out.
  bool _hadUser = false;

  /// Pending retry after a failed anonymous sign-in (e.g. offline at launch).
  Timer? _retryTimer;
  int _retryAttempt = 0;

  /// Signs in anonymously so a profile can be created before the user commits
  /// to an account.
  Future<void> start() async {
    if (_signingIn || _auth.currentUser != null) return;
    _signingIn = true;
    _retryTimer?.cancel();
    try {
      await _auth.ensureSignedIn();
      _retryAttempt = 0;
    } catch (e, s) {
      AnalyticsService.reportError('AuthCubit', 'start', e, stack: s);
      emit(state.copyWith(status: AuthStatus.failed, error: e));
      _scheduleRetry();
    } finally {
      _signingIn = false;
    }
  }

  /// Without a uid the splash never lifts, so keep retrying with a capped
  /// backoff (2s, 4s, 8s … 30s) until sign-in succeeds.
  void _scheduleRetry() {
    if (isClosed) return;
    final seconds = min(30, 2 << _retryAttempt.clamp(0, 4));
    _retryAttempt++;
    debugPrint('[AuthCubit] retrying sign-in in ${seconds}s');
    _retryTimer = Timer(Duration(seconds: seconds), start);
  }

  void _onUserChanged(User? user) {
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unknown));
      // Only re-sign-in after a real sign-out; the initial null is expected
      // while the constructor's start() is still in flight.
      if (_hadUser) unawaited(start());
      return;
    }
    _hadUser = true;
    final signedIn = !user.isAnonymous;
    emit(
      state.copyWith(
        status: signedIn ? AuthStatus.signedIn : AuthStatus.anonymous,
        uid: user.uid,
        displayName: user.displayName,
        busy: false,
        clearError: true,
      ),
    );
    unawaited(_analytics.identify(user.uid, properties: {'signed_in': signedIn}));
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(busy: true, clearError: true));
    unawaited(_analytics.capture(AnalyticsEvents.signInStarted));
    try {
      await _auth.signInWithApple();
      unawaited(_analytics.capture(AnalyticsEvents.signInCompleted));
    } catch (e, s) {
      // Closing the Apple sheet is a choice, not a failure — no banner.
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[AuthCubit] signInWithApple canceled');
        emit(state.copyWith(busy: false));
        return;
      }
      AnalyticsService.reportError('AuthCubit', 'signInWithApple', e, stack: s);
      emit(state.copyWith(busy: false, error: e));
    }
  }

  /// Signs into an existing account by email. Returns whether it worked.
  Future<bool> signInWithEmail(String email, String password) async {
    emit(state.copyWith(busy: true, clearError: true));
    unawaited(_analytics.capture(AnalyticsEvents.signInStarted, properties: {'method': 'email'}));
    try {
      await _auth.signInWithEmail(email, password);
      unawaited(_analytics.capture(AnalyticsEvents.signInCompleted, properties: {'method': 'email'}));
      return true;
    } catch (e, s) {
      AnalyticsService.reportError('AuthCubit', 'signInWithEmail', e, stack: s);
      emit(state.copyWith(busy: false, error: e));
      return false;
    }
  }

  /// Returns whether the user was signed out.
  Future<bool> signOut() async {
    try {
      await _analytics.reset();
      await _auth.signOut();
      return true;
    } catch (e, s) {
      AnalyticsService.reportError('AuthCubit', 'signOut', e, stack: s);
      emit(state.copyWith(error: e));
      return false;
    }
  }

  /// Returns whether the account was deleted.
  Future<bool> deleteAccount() async {
    try {
      await _auth.deleteAccount();
      return true;
    } catch (e, s) {
      AnalyticsService.reportError('AuthCubit', 'deleteAccount', e, stack: s);
      emit(state.copyWith(error: e));
      return false;
    }
  }

  /// Clears a surfaced error once the UI has shown it.
  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _subscription.cancel();
    _retryTimer?.cancel();
    return super.close();
  }
}
