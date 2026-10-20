import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تنظیمات کاربر با ذخیره‌سازی محلی
class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String name = '';
  int age = 0;
  String gender = 'نامشخص';
  int waterGoal = 8;
  int stepGoal = 6000;
  bool reminderEnabled = false;
  String reminderTime = '20:00';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[p.getInt('themeMode') ?? 0];
    name = p.getString('name') ?? '';
    age = p.getInt('age') ?? 0;
    gender = p.getString('gender') ?? 'نامشخص';
    waterGoal = p.getInt('waterGoal') ?? 8;
    stepGoal = p.getInt('stepGoal') ?? 6000;
    reminderEnabled = p.getBool('reminderEnabled') ?? false;
    reminderTime = p.getString('reminderTime') ?? '20:00';
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('themeMode', themeMode.index);
    await p.setString('name', name);
    await p.setInt('age', age);
    await p.setString('gender', gender);
    await p.setInt('waterGoal', waterGoal);
    await p.setInt('stepGoal', stepGoal);
    await p.setBool('reminderEnabled', reminderEnabled);
    await p.setString('reminderTime', reminderTime);
  }

  void setThemeMode(ThemeMode v) {
    themeMode = v;
    _persist();
    notifyListeners();
  }

  void setName(String v) {
    name = v;
    _persist();
    notifyListeners();
  }

  void setAge(int v) {
    age = v;
    _persist();
    notifyListeners();
  }

  void setGender(String v) {
    gender = v;
    _persist();
    notifyListeners();
  }

  void setWaterGoal(int v) {
    waterGoal = v;
    _persist();
    notifyListeners();
  }

  void setStepGoal(int v) {
    stepGoal = v;
    _persist();
    notifyListeners();
  }

  void setReminderEnabled(bool v) {
    reminderEnabled = v;
    _persist();
    notifyListeners();
  }

  void setReminderTime(String v) {
    reminderTime = v;
    _persist();
    notifyListeners();
  }
}
