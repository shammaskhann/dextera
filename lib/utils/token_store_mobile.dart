/// Non-web implementation: simple in-memory token.
class TokenStoreImpl {
  static String? _token;

  static String? get token => _token;

  static Future<void> setToken(String? value) async {
    _token = value;
  }
}

