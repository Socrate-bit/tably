import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import 'app.dart';
import 'features/subscription/service/paywall_service.dart';
import 'firebase_options.dart';

/// PostHog project credentials. Override at build time:
/// `flutter run --dart-define=POSTHOG_API_KEY=phc_...`
const _posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
const _posthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://eu.i.posthog.com',
);

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash up only through basic initialisation below.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[main] Firebase initialised');
  } catch (e) {
    debugPrint('[main] Firebase initialisation failed: $e');
  }

  await _initAnalytics();
  _initPaywall();

  runApp(const TablyApp());
  // Anything slower (auth, profile) shows a spinner in RootScreen instead.
  FlutterNativeSplash.remove();
}

/// Starts Superwall when a key is configured; without one the paywall simply
/// never shows and the rest of the app is unaffected.
void _initPaywall() {
  if (!PaywallService.isEnabled) {
    debugPrint('[main] Superwall key not set — paywall disabled');
    return;
  }
  try {
    // Match paywall copy to the device locale (e.g. "fr_FR", "en_US").
    final options = SuperwallOptions()..localeIdentifier = Platform.localeName;
    Superwall.configure(PaywallService.apiKey, options: options);
    debugPrint('[main] Superwall initialised');
  } catch (e) {
    debugPrint('[main] Superwall initialisation failed: $e');
  }
}

/// Starts PostHog when a key is configured; the app runs fine without one.
Future<void> _initAnalytics() async {
  if (_posthogApiKey.isEmpty) {
    debugPrint('[main] PostHog key not set — analytics disabled');
    return;
  }
  try {
    await Posthog().setup(
      PostHogConfig(_posthogApiKey)
        ..host = _posthogHost
        ..captureApplicationLifecycleEvents = true,
    );
    debugPrint('[main] PostHog initialised');
  } catch (e) {
    debugPrint('[main] PostHog initialisation failed: $e');
  }
}
