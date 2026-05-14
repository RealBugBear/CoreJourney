import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhyhMSeKeohmJfbKus6qWgX10_SZiwr-Q',
    appId: '1:673501917704:android:63ddd42b1717d282e657bd',
    messagingSenderId: '673501917704',
    projectId: 'corejourney-prod',
    storageBucket: 'corejourney-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAK9_s9KUMTSG3p9NOKebWRenxjjbuKPeU',
    appId: '1:673501917704:ios:9446cd7e1a342713e657bd',
    messagingSenderId: '673501917704',
    projectId: 'corejourney-prod',
    storageBucket: 'corejourney-prod.firebasestorage.app',
    iosBundleId: 'com.alexandermessinger.corejourney',
  );
}
