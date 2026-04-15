import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/thread.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static const String _threadsKey = 'threads';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      return AppSettings.fromJson(jsonDecode(settingsJson));
    }

    return AppSettings.empty();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }

  // Thread storage
  Future<List<Thread>> loadThreads() async {
    final prefs = await SharedPreferences.getInstance();
    final threadsJson = prefs.getString(_threadsKey);

    if (threadsJson != null) {
      final List<dynamic> threadsList = jsonDecode(threadsJson);
      return threadsList.map((json) => Thread.fromJson(json)).toList();
    }

    return [];
  }

  Future<void> saveThread(Thread thread) async {
    final threads = await loadThreads();

    // Check if thread already exists
    final existingIndex = threads.indexWhere((t) => t.id == thread.id);
    if (existingIndex >= 0) {
      threads[existingIndex] = thread;
    } else {
      threads.insert(0, thread);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _threadsKey,
      jsonEncode(threads.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> deleteThread(String threadId) async {
    final threads = await loadThreads();
    threads.removeWhere((t) => t.id == threadId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _threadsKey,
      jsonEncode(threads.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> clearThreads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_threadsKey);
  }
}
