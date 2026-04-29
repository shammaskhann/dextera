import 'dart:html' as html;

Future<void> saveTokenPlatform(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> removeTokenPlatform(String key) async {
  html.window.localStorage.remove(key);
}

Future<String?> getTokenPlatform(String key) async {
  return html.window.localStorage[key];
}

Future<void> saveUserPlatform(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> removeUserPlatform(String key) async {
  html.window.localStorage.remove(key);
}

Future<String?> getUserPlatform(String key) async {
  return html.window.localStorage[key];
}
