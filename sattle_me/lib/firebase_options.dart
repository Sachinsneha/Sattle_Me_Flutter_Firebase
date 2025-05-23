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
    apiKey: 'AIzaSyCT2YKM_W3szaDBAc5ZCvZCqHpL461pfuk',
    appId: '1:1049339323080:web:d1e2e4aa0be0bb5f633bfd',
    messagingSenderId: '1049339323080',
    projectId: 'loginsystem-1da96',
    authDomain: 'loginsystem-1da96.firebaseapp.com',
    databaseURL: 'https://loginsystem-1da96-default-rtdb.firebaseio.com',
    storageBucket: 'loginsystem-1da96.firebasestorage.app',
    measurementId: 'G-5YRHYY5D6Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBELzW864fKML_Xl9OBfCx_uckgLWd-It8',
    appId: '1:1049339323080:android:ccaa10879ce63b3c633bfd',
    messagingSenderId: '1049339323080',
    projectId: 'loginsystem-1da96',
    databaseURL: 'https://loginsystem-1da96-default-rtdb.firebaseio.com',
    storageBucket: 'loginsystem-1da96.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4nf-5AXRr9eo1fx7av9q6yg0OqV8dguw',
    appId: '1:1049339323080:ios:75f9a0eaddc5d146633bfd',
    messagingSenderId: '1049339323080',
    projectId: 'loginsystem-1da96',
    databaseURL: 'https://loginsystem-1da96-default-rtdb.firebaseio.com',
    storageBucket: 'loginsystem-1da96.firebasestorage.app',
    iosClientId: '1049339323080-b87499vqsqhq7almkqub42nvt1go59s6.apps.googleusercontent.com',
    iosBundleId: 'com.example.sattleMe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC4nf-5AXRr9eo1fx7av9q6yg0OqV8dguw',
    appId: '1:1049339323080:ios:75f9a0eaddc5d146633bfd',
    messagingSenderId: '1049339323080',
    projectId: 'loginsystem-1da96',
    databaseURL: 'https://loginsystem-1da96-default-rtdb.firebaseio.com',
    storageBucket: 'loginsystem-1da96.firebasestorage.app',
    iosClientId: '1049339323080-b87499vqsqhq7almkqub42nvt1go59s6.apps.googleusercontent.com',
    iosBundleId: 'com.example.sattleMe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCT2YKM_W3szaDBAc5ZCvZCqHpL461pfuk',
    appId: '1:1049339323080:web:b77d0960392496b1633bfd',
    messagingSenderId: '1049339323080',
    projectId: 'loginsystem-1da96',
    authDomain: 'loginsystem-1da96.firebaseapp.com',
    databaseURL: 'https://loginsystem-1da96-default-rtdb.firebaseio.com',
    storageBucket: 'loginsystem-1da96.firebasestorage.app',
    measurementId: 'G-M94XYEM4BR',
  );
}
