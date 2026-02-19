import 'token_store_mobile.dart'
    if (dart.library.html) 'token_store_web.dart' as impl;

/// Cross-platform token store.
/// - On Flutter Web: persists token in `window.localStorage`
/// - On other platforms: keeps token in memory for this app session
class TokenStore {
  static String? get token => impl.TokenStoreImpl.token;

  static set token(String? value) {
    impl.TokenStoreImpl.setToken(value);
  }

  static Future<void> clear() async {
    await impl.TokenStoreImpl.setToken(null);
  }
}

