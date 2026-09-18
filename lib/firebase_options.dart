// File generated from the Tably Firebase project (tably-9f3c2).
// Regenerate with: flutterfire configure --project=tably-9f3c2
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration per platform.
///
/// ```dart
/// import 'firebase_options.dart';
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyANvBi3XYnOWL9ExMqG9xpQQLrdXwGsOhs',
    appId: '1:444020010379:web:707246548aa141f3fc538e',
    messagingSenderId: '444020010379',
    projectId: 'tably-9f3c2',
    authDomain: 'tably-9f3c2.firebaseapp.com',
    storageBucket: 'tably-9f3c2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUS_NYlTbI1Tt9sxmerblUmKI7OLHT0Ew',
    appId: '1:444020010379:ios:e064cd1dcd551661fc538e',
    messagingSenderId: '444020010379',
    projectId: 'tably-9f3c2',
    storageBucket: 'tably-9f3c2.firebasestorage.app',
    iosBundleId: 'com.appscales.tably',
  );
}
