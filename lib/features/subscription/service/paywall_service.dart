import 'package:flutter/foundation.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

/// Where the subscription gate stands. [unknown] until Superwall reports, which
/// is also the permanent state when no Superwall key is configured.
enum SubscriptionGateStatus { unknown, active, inactive }

/// The only file that touches the Superwall SDK, so cubits stay testable and
/// every failure is swallowed rather than breaking a user flow.
class PaywallService {
  const PaywallService();

  /// Placement configured in the Superwall dashboard, fired once when the user
  /// finishes onboarding.
  static const onboardingCompletePlacement = 'onboarding_complete';

  /// Live entitlement, mapped off Superwall's own stream. Yields nothing when
  /// Superwall is unconfigured, leaving the gate [SubscriptionGateStatus.unknown]
  /// so a missing key can never break the app.
  Stream<SubscriptionGateStatus> get status {
    try {
      return Superwall.shared.subscriptionStatus.map(_map).handleError((Object e) {
        debugPrint('[PaywallService] status stream failed: $e');
      });
    } catch (e) {
      debugPrint('[PaywallService] status unavailable: $e');
      return const Stream.empty();
    }
  }

  SubscriptionGateStatus _map(SubscriptionStatus status) => switch (status) {
        SubscriptionStatusActive() => SubscriptionGateStatus.active,
        SubscriptionStatusInactive() => SubscriptionGateStatus.inactive,
        SubscriptionStatusUnknown() => SubscriptionGateStatus.unknown,
      };

  /// Ties paywall and purchases to the Firebase uid, the same id PostHog uses.
  Future<void> identify(String uid) async {
    try {
      await Superwall.shared.identify(uid);
      debugPrint('[PaywallService] identified $uid');
    } catch (e) {
      debugPrint('[PaywallService] identify failed: $e');
    }
  }

  /// Clears the identity so a new anonymous user starts clean.
  Future<void> reset() async {
    try {
      await Superwall.shared.reset();
    } catch (e) {
      debugPrint('[PaywallService] reset failed: $e');
    }
  }

  /// Asks Superwall to show the paywall for a placement. A no-op when no key is
  /// configured or the dashboard has no paywall for this placement.
  Future<void> present(String placement) async {
    try {
      await Superwall.shared.registerPlacement(placement);
      debugPrint('[PaywallService] presented "$placement"');
    } catch (e) {
      debugPrint('[PaywallService] present "$placement" failed: $e');
    }
  }
}
