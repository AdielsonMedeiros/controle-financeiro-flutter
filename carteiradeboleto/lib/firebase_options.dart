import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCvz1xf0isFeBbDOqzx2rn1HTFQIUgauI4',
    appId: '1:458889744867:web:e4c8b4953bcac5d28f90d6',
    messagingSenderId: '458889744867',
    projectId: 'carteira-de-boletos-a05ea',
    authDomain: 'carteira-de-boletos-a05ea.firebaseapp.com',
    storageBucket: 'carteira-de-boletos-a05ea.firebasestorage.app',
    measurementId: 'G-XZ6Q7GJ1BZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcnUq3i921mUV66B7r01cP0zdgpC5aJ8U',
    appId: '1:458889744867:android:aa0115ed86dc6b0d8f90d6',
    messagingSenderId: '458889744867',
    projectId: 'carteira-de-boletos-a05ea',
    storageBucket: 'carteira-de-boletos-a05ea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQhIrIv0fbm_tEo4nrOx-VsCYaRuKAUn8',
    appId: '1:458889744867:ios:16953f38effbe68f8f90d6',
    messagingSenderId: '458889744867',
    projectId: 'carteira-de-boletos-a05ea',
    storageBucket: 'carteira-de-boletos-a05ea.firebasestorage.app',
    androidClientId: '458889744867-gq99sl7cfpdl87tqu313ec8ph9c0ia8s.apps.googleusercontent.com',
    iosClientId: '458889744867-q7d2mk757bspu7qrkap1liu5qi2a2j5g.apps.googleusercontent.com',
    iosBundleId: 'br.com.adielsontech.carteiradeboleto',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAQhIrIv0fbm_tEo4nrOx-VsCYaRuKAUn8',
    appId: '1:458889744867:ios:bf6a41872a4a483b8f90d6',
    messagingSenderId: '458889744867',
    projectId: 'carteira-de-boletos-a05ea',
    storageBucket: 'carteira-de-boletos-a05ea.firebasestorage.app',
    iosBundleId: 'com.example.carteiraDeBoleto',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCvz1xf0isFeBbDOqzx2rn1HTFQIUgauI4',
    appId: '1:458889744867:web:b55484da42ab52e38f90d6',
    messagingSenderId: '458889744867',
    projectId: 'carteira-de-boletos-a05ea',
    authDomain: 'carteira-de-boletos-a05ea.firebaseapp.com',
    storageBucket: 'carteira-de-boletos-a05ea.firebasestorage.app',
    measurementId: 'G-6SGX3VFWH3',
  );
}