import 'package:flutter/foundation.dart' show kIsWeb;

/// Public web pages hosted next to the Flutter web build (Netlify).
abstract final class GlowWebLinks {
  static const String _defaultOrigin = 'https://tubular-pixie-00c69b.netlify.app';

  /// Override with `--dart-define=WEB_APP_ORIGIN=https://your-site.netlify.app`
  static const String _envOrigin = String.fromEnvironment('WEB_APP_ORIGIN', defaultValue: '');

  static String get origin {
    if (_envOrigin.trim().isNotEmpty) {
      return _envOrigin.trim().replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return _defaultOrigin;
  }

  static String get installPage => '$origin/install.html';
  static String get privacyPage => '$origin/privacy.html';
  static String get appHome => '$origin/';
}
