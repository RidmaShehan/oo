// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
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
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDvjejCavLpfBjmb9El3Cdh4GsXlEq1sIk',
    appId: '1:439411967957:web:230238e5b16763d1239f5c',
    messagingSenderId: '439411967957',
    projectId: 'seaventure-e4ddc',
    authDomain: 'seaventure-e4ddc.firebaseapp.com',
    storageBucket: 'seaventure-e4ddc.firebasestorage.app',
    measurementId: 'G-BTYE4JZX0L',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0GJgScuCQPDKsVVT1wbfHoZFbGpdKUC0',
    appId: '1:439411967957:android:761dd28a5a68a8d6239f5c',
    messagingSenderId: '439411967957',
    projectId: 'seaventure-e4ddc',
    storageBucket: 'seaventure-e4ddc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzO4cC8Fii_K6IOh7YEd5v88e0dW5G8O8',
    appId: '1:439411967957:ios:76c75b12ec4447cc239f5c',
    messagingSenderId: '439411967957',
    projectId: 'seaventure-e4ddc',
    storageBucket: 'seaventure-e4ddc.firebasestorage.app',
    iosClientId: '439411967957-r1o1v4rh3sqv5am869gdmosmthku9fpe.apps.googleusercontent.com',
    iosBundleId: 'com.example.seaventu',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDzO4cC8Fii_K6IOh7YEd5v88e0dW5G8O8',
    appId: '1:439411967957:ios:76c75b12ec4447cc239f5c',
    messagingSenderId: '439411967957',
    projectId: 'seaventure-e4ddc',
    storageBucket: 'seaventure-e4ddc.firebasestorage.app',
    iosClientId: '439411967957-r1o1v4rh3sqv5am869gdmosmthku9fpe.apps.googleusercontent.com',
    iosBundleId: 'com.example.seaventu',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDvjejCavLpfBjmb9El3Cdh4GsXlEq1sIk',
    appId: '1:439411967957:web:77c53ffed7597d31239f5c',
    messagingSenderId: '439411967957',
    projectId: 'seaventure-e4ddc',
    authDomain: 'seaventure-e4ddc.firebaseapp.com',
    storageBucket: 'seaventure-e4ddc.firebasestorage.app',
    measurementId: 'G-GX0CHQH9FY',
  );

}