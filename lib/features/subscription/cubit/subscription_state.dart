part of 'subscription_cubit.dart';

/// Where a referral code redemption stands, so the dialog can show progress and
/// a precise error.
enum RedeemStatus { idle, submitting, success, invalid, exhausted, alreadyUsed, failed }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionGateStatus.unknown,
    this.userType = UserType.normal,
    this.redeemStatus = RedeemStatus.idle,
  });

  final SubscriptionGateStatus status;
  final UserType userType;
  final RedeemStatus redeemStatus;

  bool get isActive => status == SubscriptionGateStatus.active;

  /// The referral bypass: an admin or creator never sees the paywall.
  bool get skipsPaywall => userType.skipsPaywall;

  /// True when the user may use the app without being asked to pay.
  bool get hasAccess => skipsPaywall || isActive;

  /// True once [hasAccess] can be trusted: a granted type is known up front,
  /// anyone else waits for Superwall so the paywall never flashes at them.
  bool get isResolved => skipsPaywall || status != SubscriptionGateStatus.unknown;

  bool get isSubmitting => redeemStatus == RedeemStatus.submitting;

  SubscriptionState copyWith({
    SubscriptionGateStatus? status,
    UserType? userType,
    RedeemStatus? redeemStatus,
  }) =>
      SubscriptionState(
        status: status ?? this.status,
        userType: userType ?? this.userType,
        redeemStatus: redeemStatus ?? this.redeemStatus,
      );

  @override
  List<Object?> get props => [status, userType, redeemStatus];
}
