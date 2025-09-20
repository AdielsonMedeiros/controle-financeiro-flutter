

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
    apiKey: 'AIzaSyCtnR4Mzt1Z_8H9mKg8SuSn090DluB2cOs',
    appId: '1:469665350572:web:1bf59b3a31cc2589ba7009',
    messagingSenderId: '469665350572',
    projectId: 'meu-controle-financeiro-f2cdb',
    authDomain: 'meu-controle-financeiro-f2cdb.firebaseapp.com',
    storageBucket: 'meu-controle-financeiro-f2cdb.firebasestorage.app',
    measurementId: 'G-9STKVTXJFZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJWvl28U_o9Fe_oR5TKaZc92jO-te3K4w',
    appId: '1:469665350572:android:04e8da086626cd20ba7009',
    messagingSenderId: '469665350572',
    projectId: 'meu-controle-financeiro-f2cdb',
    storageBucket: 'meu-controle-financeiro-f2cdb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArjycJ--hRk5jaCdEqd4_bCuuHNAsDJ-o',
    appId: '1:469665350572:ios:5f62afd513d9390eba7009',
    messagingSenderId: '469665350572',
    projectId: 'meu-controle-financeiro-f2cdb',
    storageBucket: 'meu-controle-financeiro-f2cdb.firebasestorage.app',
    iosClientId: '469665350572-gjkurdpnh7orb188smgpnmof19a4vsi6.apps.googleusercontent.com',
    iosBundleId: 'com.example.controleFinanceiroApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArjycJ--hRk5jaCdEqd4_bCuuHNAsDJ-o',
    appId: '1:469665350572:ios:5f62afd513d9390eba7009',
    messagingSenderId: '469665350572',
    projectId: 'meu-controle-financeiro-f2cdb',
    storageBucket: 'meu-controle-financeiro-f2cdb.firebasestorage.app',
    iosClientId: '469665350572-gjkurdpnh7orb188smgpnmof19a4vsi6.apps.googleusercontent.com',
    iosBundleId: 'com.example.controleFinanceiroApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBQoTH2OzuTS5dDxdS3BMFzfubbZayayts',
    appId: '1:469665350572:web:4555d18f7b7e8b85ba7009',
    messagingSenderId: '469665350572',
    projectId: 'meu-controle-financeiro-f2cdb',
    authDomain: 'meu-controle-financeiro-f2cdb.firebaseapp.com',
    storageBucket: 'meu-controle-financeiro-f2cdb.firebasestorage.app',
    measurementId: 'G-EFX9LZEP4E',
  );
}
