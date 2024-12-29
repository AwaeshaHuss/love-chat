import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static SharedPreferences? _preferences;

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Save a string value
  static Future<bool> saveString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  /// Get a string value
  static String? getString(String key) {
    return _preferences?.getString(key);
  }

  /// Save an integer value
  static Future<bool> saveInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  /// Get an integer value
  static int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  /// Save a boolean value
  static Future<bool> saveBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  /// Get a boolean value
  static bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  /// Save a double value
  static Future<bool> saveDouble(String key, double value) async {
    return await _preferences?.setDouble(key, value) ?? false;
  }

  /// Get a double value
  static double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }

  /// Save a list of strings
  static Future<bool> saveStringList(String key, List<String> value) async {
    return await _preferences?.setStringList(key, value) ?? false;
  }

  /// Get a list of strings
  static List<String>? getStringList(String key) {
    return _preferences?.getStringList(key);
  }

  /// Remove a value
  static Future<bool> remove(String key) async {
    return await _preferences?.remove(key) ?? false;
  }

  /// Clear all values
  static Future<bool> clear() async {
    return await _preferences?.clear() ?? false;
  }
}
