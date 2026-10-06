import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/user_type.dart';
import 'package:tably/features/subscription/cubit/subscription_cubit.dart';
import 'package:tably/features/subscription/service/paywall_service.dart';

void main() {
  group('UserType', () {
    test('parses the ids the function writes', () {
      expect(UserType.fromId('admin'), UserType.admin);
      expect(UserType.fromId('ugc'), UserType.ugc);
      expect(UserType.fromId('normal'), UserType.normal);
    });

    test('anything unknown or absent is a paying user', () {
      expect(UserType.fromId(null), UserType.normal);
      expect(UserType.fromId(''), UserType.normal);
      expect(UserType.fromId('Admin'), UserType.normal);
      expect(UserType.fromId('superuser'), UserType.normal);
    });

    test('only a granted type skips the paywall', () {
      expect(UserType.admin.skipsPaywall, isTrue);
      expect(UserType.ugc.skipsPaywall, isTrue);
      expect(UserType.normal.skipsPaywall, isFalse);
    });
  });

  group('SubscriptionState.hasAccess', () {
    test('a normal user without a subscription is gated', () {
      const state = SubscriptionState(status: SubscriptionGateStatus.inactive);
      expect(state.hasAccess, isFalse);
    });

    test('an unresolved gate does not grant access on its own', () {
      const state = SubscriptionState();
      expect(state.status, SubscriptionGateStatus.unknown);
      expect(state.hasAccess, isFalse);
    });

    test('a subscription grants access', () {
      const state = SubscriptionState(status: SubscriptionGateStatus.active);
      expect(state.hasAccess, isTrue);
    });

    test('a referral grant bypasses an inactive subscription', () {
      for (final type in [UserType.admin, UserType.ugc]) {
        final state = SubscriptionState(
          status: SubscriptionGateStatus.inactive,
          userType: type,
        );
        expect(state.hasAccess, isTrue, reason: '${type.id} should bypass');
        expect(state.skipsPaywall, isTrue);
      }
    });

    test('a referral grant bypasses before the gate has even resolved', () {
      // The case that matters at launch: no paywall flash for a code holder.
      const state = SubscriptionState(userType: UserType.admin);
      expect(state.hasAccess, isTrue);
    });
  });

  group('SubscriptionState.isResolved', () {
    test('a normal user waits for Superwall', () {
      expect(const SubscriptionState().isResolved, isFalse);
      expect(const SubscriptionState(status: SubscriptionGateStatus.inactive).isResolved, isTrue);
      expect(const SubscriptionState(status: SubscriptionGateStatus.active).isResolved, isTrue);
    });

    test('a referral grant is resolved before Superwall reports', () {
      expect(const SubscriptionState(userType: UserType.admin).isResolved, isTrue);
      expect(const SubscriptionState(userType: UserType.ugc).isResolved, isTrue);
    });
  });
}
