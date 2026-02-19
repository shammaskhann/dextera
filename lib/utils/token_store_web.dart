// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation: store token in window.localStorage.
class TokenStoreImpl {
  static const _key = 'dextera_auth_token';

  static String? get token {
    return html.window.localStorage[_key];
  }

  static Future<void> setToken(String? value) async {
    if (value == null || value.isEmpty) {
      html.window.localStorage.remove(_key);
    } else {
      html.window.localStorage[_key] = value;
    }
  }
}

