// File generated from the existing animal-insurance-323b4 Firebase project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('LIMS is an Android-only app.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('LIMS is an Android-only app; ${defaultTargetPlatform.name} is not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsuucGPREXw6IdYxzm7nTRyTvp1OalhDw',
    appId: '1:574251214201:android:f06718f42aa1b876a33ba8',
    messagingSenderId: '574251214201',
    projectId: 'animal-insurance-323b4',
    storageBucket: 'animal-insurance-323b4.firebasestorage.app',
  );
}
