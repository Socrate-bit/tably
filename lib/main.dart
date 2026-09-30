import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
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

/// A debug token registered in the Firebase console (App Check → Manage debug
/// tokens), for simulators and the web build:
/// `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=...`
const _appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// reCAPTCHA v3 site key for release web builds.
const _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

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

  await _initAppCheck();
  await _initAnalytics();
  _initPaywall();
  await _initGlass();

  // `brightnessResolver` lets the glass follow the app theme rather than the
  // raw OS brightness, which MaterialApp would otherwise win.
  runApp(LiquidGlassWidgets.wrap(brightnessResolver: Theme.maybeBrightnessOf, child: const TablyApp()));
  // Anything slower (auth, profile) shows a spinner in RootScreen instead.
  FlutterNativeSplash.remove();
}

/// Firebase AI Logic enforces App Check, so Gemini calls fail without it.
/// Debug builds use the debug provider (register its token in the console);
/// release builds attest with DeviceCheck on iOS and reCAPTCHA on the web.
Future<void> _initAppCheck() async {
  final debugToken = _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken;
  try {
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode ? AppleDebugProvider(debugToken: debugToken) : const AppleDeviceCheckProvider(),
      providerWeb: kDebugMode ? WebDebugProvider(debugToken: debugToken) : ReCaptchaV3Provider(_recaptchaSiteKey),
    );
    debugPrint('[main] App Check activated (${kDebugMode ? 'debug' : 'release'} provider)');
  } catch (e) {
    debugPrint('[main] App Check activation failed: $e');
  }
}

/// Pre-warms the liquid-glass shaders so the tab bar renders on its first
/// frame. Failure only costs a brief placeholder, so it never blocks launch.
Future<void> _initGlass() async {
  try {
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
    debugPrint('[main] Liquid glass shaders warmed');
  } catch (e) {
    debugPrint('[main] Liquid glass warm-up failed: $e');
  }
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
