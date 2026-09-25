import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class StorageService {
  StorageService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const settingsKey = 'sms_remote_settings_v1';
  final SharedPreferencesAsync _preferences;

  Future<AppSettings> load() async {
    final saved = await _preferences.getString(settingsKey);
    if (saved == null) return AppSettings.defaults();
    final json = jsonDecode(saved);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Impostazioni non valide.');
    }
    return AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) async {
    if (!settings.isReady) {
      throw ArgumentError('Completa le impostazioni prima di salvarle.');
    }
    await _preferences.setString(settingsKey, jsonEncode(settings.toJson()));
  }
}
