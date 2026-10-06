import 'package:flutter/foundation.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../../core/analytics/analytics_service.dart';

/// Where the subscription gate stands. [unknown] until Superwall reports.
enum SubscriptionGateStatus { unknown, active, inactive }

/// The only file that touches the Superwall SDK, so cubits stay testable and
/// every failure is swallowed rather than breaking a user flow.
class PaywallService {
  const PaywallService();

  /// Superwall publishable key, which owns the paywall remotely. Override with
  /// `flutter run --dart-define=SUPERWALL_API_KEY=pk_...`
  static const apiKey = String.fromEnvironment('SUPERWALL_API_KEY', defaultValue: 'pk_Ibeqi31IjHRVk-NaR25kS');

  /// Touching `Superwall.shared` before `configure()` is a native assertion
  /// that Dart can't catch, so every call is skipped without a key. The SDK has
  /// no web implementation, so the web build runs without a paywall.
  static bool get isEnabled => !kIsWeb && apiKey.isNotEmpty;

  /// Placement configured in the Superwall dashboard, carrying the paywall shown
  /// when onboarding ends and every time a user without access touches the app.
  static const onboardingEndPlacement = 'onboarding_end';

  /// The Superwall entitlement that unlocks the app.
  static const proEntitlement = 'pro';

  /// Live entitlement, mapped off Superwall's own stream. Yields nothing when
  /// Superwall is unconfigured.
  Stream<SubscriptionGateStatus> get status {
    if (!isEnabled) return const Stream.empty();
    try {
      return Superwall.shared.subscriptionStatus.map(mapStatus).handleError((Object e, StackTrace s) {
        AnalyticsService.reportError('PaywallService', 'status stream', e, stack: s);
      });
    } catch (e, s) {
      AnalyticsService.reportError('PaywallService', 'status', e, stack: s);
      return const Stream.empty();
    }
  }

  /// Only an active [proEntitlement] counts — any other entitlement is inactive.
  @visibleForTesting
  static SubscriptionGateStatus mapStatus(SubscriptionStatus status) => switch (status) {
        SubscriptionStatusActive(:final entitlements) => entitlements.any((e) => e.id == proEntitlement)
            ? SubscriptionGateStatus.active
            : SubscriptionGateStatus.inactive,
        SubscriptionStatusInactive() => SubscriptionGateStatus.inactive,
        SubscriptionStatusUnknown() => SubscriptionGateStatus.unknown,
      };

  /// Ties paywall and purchases to the Firebase uid, the same id Mixpanel uses.
  Future<void> identify(String uid) async {
    if (!isEnabled) return;
    try {
      await Superwall.shared.identify(uid);
      debugPrint('[PaywallService] identified $uid');
    } catch (e, s) {
      AnalyticsService.reportError('PaywallService', 'identify', e, stack: s);
    }
  }

  /// Clears the identity so a new anonymous user starts clean.
  Future<void> reset() async {
    if (!isEnabled) return;
    try {
      await Superwall.shared.reset();
    } catch (e, s) {
      AnalyticsService.reportError('PaywallService', 'reset', e, stack: s);
    }
  }

  /// Asks Superwall to show the paywall for a placement. A no-op when no key is
  /// configured or the dashboard has no paywall for this placement.
  Future<void> present(String placement) async {
    if (!isEnabled) return;
    try {
      await Superwall.shared.registerPlacement(placement);
      debugPrint('[PaywallService] presented "$placement"');
    } catch (e, s) {
      AnalyticsService.reportError('PaywallService', 'present $placement', e, stack: s);
    }
  }
}
