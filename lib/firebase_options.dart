// Generated manually from google-services.json and GoogleService-Info.plist
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8Smd09zdrHgrybZSRmddZN7TNfn8GZNQ',
    appId: '1:200920654018:android:62cba1d1c9be010b309b5b',
    messagingSenderId: '200920654018',
    projectId: 'motogate-app-47342',
    storageBucket: 'motogate-app-47342.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDB_9L6ooGLP8bGIQntp7YE2_NeJn0cUMs',
    appId: '1:200920654018:ios:37de27990d713dc8309b5b',
    messagingSenderId: '200920654018',
    projectId: 'motogate-app-47342',
    storageBucket: 'motogate-app-47342.firebasestorage.app',
    iosBundleId: 'com.example.motogateApp',
  );
}
