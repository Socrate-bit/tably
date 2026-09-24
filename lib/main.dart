import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'app.dart';
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
  // Keep the native splash up until RootScreen knows what to show.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[main] Firebase initialised');
  } catch (e) {
    debugPrint('[main] Firebase initialisation failed: $e');
  }

  await _initAnalytics();

  runApp(const TablyApp());
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
