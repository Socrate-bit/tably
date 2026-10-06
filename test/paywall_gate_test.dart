import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/user_type.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/subscription/cubit/subscription_cubit.dart';
import 'package:tably/features/subscription/service/paywall_service.dart';
import 'package:tably/features/subscription/service/referral_service.dart';
import 'package:tably/features/subscription/widget/paywall_gate.dart';

/// Superwall stand-in: status is pushed by the test, presentations recorded.
class _FakePaywall extends PaywallService {
  final controller = StreamController<SubscriptionGateStatus>.broadcast();
  final presented = <String>[];

  @override
  Stream<SubscriptionGateStatus> get status => controller.stream;

  @override
  Future<void> present(String placement) async => presented.add(placement);

  @override
  Future<void> identify(String uid) async {}

  @override
  Future<void> reset() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePaywall paywall;
  late ProfileCubit profile;
  late SubscriptionCubit cubit;

  setUp(() {
    paywall = _FakePaywall();
    profile = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    cubit = SubscriptionCubit(
      paywall: paywall,
      referral: ReferralService(),
      profileCubit: profile,
      analytics: const AnalyticsService(),
    );
    addTearDown(() async {
      await cubit.close();
      await profile.close();
      await paywall.controller.close();
    });
  });

  Future<void> emitStatus(SubscriptionGateStatus status) async {
    paywall.controller.add(status);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> grant(UserType type) async {
    await profile.completeOnboarding(UserProfile(userType: type));
    await Future<void>.delayed(Duration.zero);
  }

  group('PaywallService.mapStatus', () {
    Entitlement entitlement(String id) => Entitlement(id: id);

    test('only the pro entitlement unlocks the app', () {
      expect(
        PaywallService.mapStatus(SubscriptionStatusActive(entitlements: {entitlement('pro')})),
        SubscriptionGateStatus.active,
      );
      expect(
        PaywallService.mapStatus(SubscriptionStatusActive(entitlements: {entitlement('other')})),
        SubscriptionGateStatus.inactive,
      );
      expect(PaywallService.mapStatus(SubscriptionStatusActive(entitlements: {})), SubscriptionGateStatus.inactive);
      expect(PaywallService.mapStatus(SubscriptionStatusInactive()), SubscriptionGateStatus.inactive);
      expect(PaywallService.mapStatus(SubscriptionStatusUnknown()), SubscriptionGateStatus.unknown);
    });
  });

  group('SubscriptionCubit.presentPaywall', () {
    test('a user without access gets the onboarding_end paywall', () async {
      await emitStatus(SubscriptionGateStatus.inactive);
      await cubit.presentPaywall();
      expect(paywall.presented, [PaywallService.onboardingEndPlacement]);
      expect(PaywallService.onboardingEndPlacement, 'onboarding_end');
    });

    test('a subscriber is never shown the paywall', () async {
      await emitStatus(SubscriptionGateStatus.active);
      await cubit.presentPaywall();
      expect(paywall.presented, isEmpty);
    });

    for (final type in [UserType.admin, UserType.ugc]) {
      test('${type.id} users bypass the paywall', () async {
        await grant(type);
        await emitStatus(SubscriptionGateStatus.inactive);
        await cubit.presentPaywall();
        expect(paywall.presented, isEmpty);
      });
    }
  });

  group('PaywallGate', () {
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: ScreenUtilInit(
          designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
          builder: (_, _) => MaterialApp(
            home: PaywallGate(
              child: Scaffold(
                body: TextButton(onPressed: () {}, child: const Text('home')),
              ),
            ),
          ),
        ),
      ),
    );

    // The cubit listens from outside the test's fake zone, so status is pushed
    // through a real async gap before pumping.
    Future<void> push(WidgetTester tester, SubscriptionGateStatus status) async {
      await tester.runAsync(() => emitStatus(status));
      await tester.pump();
    }

    testWidgets('waits for Superwall, then presents and blocks every tap', (tester) async {
      await pump(tester);
      expect(find.text('home'), findsNothing, reason: 'unresolved: spinner');
      expect(paywall.presented, isEmpty);

      await push(tester, SubscriptionGateStatus.inactive);
      expect(find.text('home'), findsOneWidget);
      expect(paywall.presented, hasLength(1), reason: 'shown as soon as the gate resolves');

      await tester.tap(find.text('home'), warnIfMissed: false);
      await tester.pump();
      expect(paywall.presented, hasLength(2), reason: 'a tap on the app re-opens the paywall');

      await push(tester, SubscriptionGateStatus.active);
      await tester.tap(find.text('home'));
      await tester.pump();
      expect(paywall.presented, hasLength(2), reason: 'subscribed: the app is unlocked');
    });

    testWidgets('a creator passes straight through without waiting for Superwall', (tester) async {
      await tester.runAsync(() => grant(UserType.ugc));
      await pump(tester);
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
      await tester.tap(find.text('home'));
      await tester.pump();
      expect(paywall.presented, isEmpty);
    });

    testWidgets('an already-resolved gate presents on launch', (tester) async {
      await tester.runAsync(() => emitStatus(SubscriptionGateStatus.inactive));
      await pump(tester);
      await tester.pump();
      expect(paywall.presented, [PaywallService.onboardingEndPlacement]);
    });

    testWidgets('losing the subscription brings the paywall back', (tester) async {
      await tester.runAsync(() => emitStatus(SubscriptionGateStatus.active));
      await pump(tester);
      await tester.pump();
      expect(paywall.presented, isEmpty);

      await push(tester, SubscriptionGateStatus.inactive);
      expect(paywall.presented, [PaywallService.onboardingEndPlacement]);
    });
  });
}
