import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  // Load Firebase credentials from environment variables
  // Environment variables are set via:
  // 1. .env file (local development)
  // 2. GitHub Actions Secrets (CI/CD)
  // 3. Build args (flutter build apk --dart-define=FIREBASE_API_KEY=...)

  static String _getEnvVar(String key, {String? defaultValue}) {
    final value = dotenv.env[key] ?? defaultValue;
    if (value == null) {
      throw Exception(
        'Missing environment variable: $key. '
        'Set in .env file, GitHub Actions Secrets, or build args.',
      );
    }
    return value;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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

  static FirebaseOptions get web {
    return FirebaseOptions(
      apiKey: _getEnvVar('FIREBASE_API_KEY'),
      appId: _getEnvVar('FIREBASE_WEB_APP_ID'),
      messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
      storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
    );
  }

  static FirebaseOptions get android {
    return FirebaseOptions(
      apiKey: _getEnvVar('FIREBASE_API_KEY'),
      appId: _getEnvVar('FIREBASE_ANDROID_APP_ID'),
      messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
      storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
    );
  }

  static FirebaseOptions get ios {
    return FirebaseOptions(
      apiKey: _getEnvVar('FIREBASE_API_KEY'),
      appId: _getEnvVar('FIREBASE_IOS_APP_ID'),
      messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
      storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: _getEnvVar('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.schoolcode.programming'),
    );
  }
}
