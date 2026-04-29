import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTokenPlatform(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> removeTokenPlatform(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}

Future<String?> getTokenPlatform(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> saveUserPlatform(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> removeUserPlatform(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}

Future<String?> getUserPlatform(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}
