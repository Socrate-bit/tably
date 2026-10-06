import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/user_type.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../service/paywall_service.dart';
import '../service/referral_service.dart';

part 'subscription_state.dart';

/// Owns access to the app: the Superwall entitlement plus the user type granted
/// by a referral code. Both arrive as streams, so redeeming a code flips
/// [SubscriptionState.hasAccess] everywhere without anything being refetched —
/// the function writes `userType`, the profile stream carries it here.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required PaywallService paywall,
    required ReferralService referral,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
  })  : _paywall = paywall,
        _referral = referral,
        _analytics = analytics,
        // Seeded from the profile rather than defaulted, so a grant already on
        // the document counts even if this cubit is built after it arrived.
        // Without Superwall (web) there is no paywall to pass, so the gate opens.
        super(SubscriptionState(
          userType: profileCubit.state.profile.userType,
          status: PaywallService.isEnabled ? SubscriptionGateStatus.unknown : SubscriptionGateStatus.active,
        )) {
    _statusSubscription = _paywall.status.listen(_onStatus);
    _profileSubscription = profileCubit.stream
        .map((s) => s.profile.userType)
        .distinct()
        .listen((userType) => emit(state.copyWith(userType: userType)));
  }

  final PaywallService _paywall;
  final ReferralService _referral;
  final AnalyticsService _analytics;
  late final StreamSubscription<SubscriptionGateStatus> _statusSubscription;
  late final StreamSubscription<UserType> _profileSubscription;
  String? _uid;

  void _onStatus(SubscriptionGateStatus status) {
    if (status == state.status) return;
    final wasActive = state.isActive;
    emit(state.copyWith(status: status));
    if (!wasActive && status == SubscriptionGateStatus.active) {
      unawaited(_analytics.capture(AnalyticsEvents.subscriptionActivated));
    } else if (wasActive && status == SubscriptionGateStatus.inactive) {
      unawaited(_analytics.capture(AnalyticsEvents.subscriptionLost));
    }
  }

  /// Ties the paywall to the signed-in user. Safe to call repeatedly — only
  /// re-identifies when the uid actually changed, clearing the old identity so a
  /// new anonymous user starts without the previous one's entitlement.
  Future<void> identify(String uid) async {
    if (_uid == uid) return;
    final hadUser = _uid != null;
    _uid = uid;
    if (hadUser) await _paywall.reset();
    await _paywall.identify(uid);
  }

  /// Redeems a referral code. The granted type is not emitted here — it arrives
  /// through the profile stream, which keeps a single source of truth.
  Future<void> redeem(String code) async {
    if (ReferralService.normalise(code).isEmpty) return;
    emit(state.copyWith(redeemStatus: RedeemStatus.submitting));
    unawaited(_analytics.capture(AnalyticsEvents.referralRedeemAttempt));
    try {
      final type = await _referral.validateCode(code);
      if (type == null) {
        _redeemFailed(RedeemStatus.invalid, 'invalid');
        return;
      }
      if (type == ReferralService.exhausted) {
        _redeemFailed(RedeemStatus.exhausted, 'exhausted');
        return;
      }
      final granted = await _referral.redeemCode(code);
      emit(state.copyWith(redeemStatus: RedeemStatus.success));
      debugPrint('[SubscriptionCubit] redeemed a code granting ${granted.id}');
      unawaited(_analytics.capture(
        AnalyticsEvents.referralRedeemSuccess,
        properties: {'user_type': granted.id},
      ));
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[SubscriptionCubit] redeem rejected: ${e.code}');
      switch (e.code) {
        case 'already-exists':
          _redeemFailed(RedeemStatus.alreadyUsed, 'already_used');
        case 'resource-exhausted':
          _redeemFailed(RedeemStatus.exhausted, 'exhausted');
        case 'not-found':
        case 'failed-precondition':
          _redeemFailed(RedeemStatus.invalid, 'invalid');
        default:
          _redeemFailed(RedeemStatus.failed, 'error');
      }
    } catch (e, s) {
      AnalyticsService.reportError('SubscriptionCubit', 'redeem', e, stack: s);
      _redeemFailed(RedeemStatus.failed, 'error');
    }
  }

  void _redeemFailed(RedeemStatus status, String reason) {
    emit(state.copyWith(redeemStatus: status));
    unawaited(_analytics.capture(
      AnalyticsEvents.referralRedeemFailed,
      properties: {'reason': reason},
    ));
  }

  void clearRedeemStatus() => emit(state.copyWith(redeemStatus: RedeemStatus.idle));

  /// Shows the paywall to a user without access — when onboarding ends, on
  /// launch, and on every tap on the gated app. Users with a redeemed code or
  /// an active subscription go straight through.
  Future<void> presentPaywall() async {
    if (state.hasAccess) {
      debugPrint('[SubscriptionCubit] paywall bypassed (${state.userType.id})');
      unawaited(_analytics.capture(
        AnalyticsEvents.paywallBypassed,
        properties: {'user_type': state.userType.id},
      ));
      return;
    }
    unawaited(_analytics.capture(AnalyticsEvents.paywallShown));
    await _paywall.present(PaywallService.onboardingEndPlacement);
  }

  @override
  Future<void> close() {
    _statusSubscription.cancel();
    _profileSubscription.cancel();
    return super.close();
  }
}
