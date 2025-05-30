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
    apiKey: 'AIzaSyB-KIrw0A2sday9wgIUtbJWDrFOsqei_YE',
    appId: '1:62549888538:web:d443de2de3f7e5b2ce4ba3',
    messagingSenderId: '62549888538',
    projectId: 'futuros-heroes',
    authDomain: 'futuros-heroes.firebaseapp.com',
    storageBucket: 'futuros-heroes.firebasestorage.app',
    measurementId: 'G-GL8W5HNR6P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDP1MMGwyTsmX5T3hfDpU_XgGYCi_nyrFE',
    appId: '1:649989230963:android:bbb80fb27810ce7e08b506',
    messagingSenderId: '649989230963',
    projectId: 'eventos-infantiles',
    storageBucket: 'eventos-infantiles.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7Gmqm9EkJrNYfH_VCQ75h5bDDuUczhnk',
    appId: '1:649989230963:ios:4d4df769a7d2ba3d08b506',
    messagingSenderId: '649989230963',
    projectId: 'eventos-infantiles',
    storageBucket: 'eventos-infantiles.firebasestorage.app',
    iosBundleId: 'com.example.eventosInfantilesWeb',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7Gmqm9EkJrNYfH_VCQ75h5bDDuUczhnk',
    appId: '1:649989230963:ios:4d4df769a7d2ba3d08b506',
    messagingSenderId: '649989230963',
    projectId: 'eventos-infantiles',
    storageBucket: 'eventos-infantiles.firebasestorage.app',
    iosBundleId: 'com.example.eventosInfantilesWeb',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyALGl3r0CWqXWjsXBPpNU--6GOYsFLxYVk',
    appId: '1:649989230963:web:6ddc60bf2149aaa508b506',
    messagingSenderId: '649989230963',
    projectId: 'eventos-infantiles',
    authDomain: 'eventos-infantiles.firebaseapp.com',
    storageBucket: 'eventos-infantiles.firebasestorage.app',
  );

}