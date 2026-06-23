import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class DietService {
  final Map<String, dynamic> _data;
  static const String _storageKey = 'diet_plans_storage';

  DietService._(this._data);

  static Future<DietService> loadFromAsset(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    return DietService._(data);
  }

  final Random _random = Random();

  Map<String, dynamic> _mealMap(String meal) {
    return _data[meal] as Map<String, dynamic>? ?? {};
  }

  String getRandomForMeal(String meal) {
    final mealMap = _mealMap(meal);
    if (mealMap.isEmpty) return 'Nessun elemento disponibile';

    final parts = <String>[];
    mealMap.forEach((category, value) {
      if (value is List && value.isNotEmpty) {
        final item = value[_random.nextInt(value.length)].toString();
        if (mealMap.length == 1) {
          parts.add(item);
        } else {
          parts.add('-$item');
        }
      }
    });

    if (parts.isEmpty) return 'Nessun elemento disponibile';
    return parts.join('\n');
  }

  Map<String, String> getRandomDailyMenu() {
    return {
      'colazione': getRandomForMeal('colazione'),
      'spuntino_ore_11': getRandomForMeal('spuntino_ore_11'),
      'pranzo': getRandomForMeal('pranzo'),
      'spuntino_ore_17': getRandomForMeal('spuntino_ore_17'),
      'cena': getRandomForMeal('cena'),
    };
  }

  Future<bool> saveDailyMenuForDate(DateTime date, Map<String, String> menu) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_storageKey) ?? '{}';
      final Map<String, dynamic> data = json.decode(content);
      
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      data[key] = menu;
      
      return await prefs.setString(_storageKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving diet plan: $e');
      return false;
    }
  }

  Future<Map<String, String>?> loadDailyMenuForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_storageKey);
      if (content == null || content.isEmpty) return null;
      
      final Map<String, dynamic> data = json.decode(content);
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final menu = data[key];
      
      if (menu == null) return null;
      
      final Map<String, String> result = {};
      (menu as Map<String, dynamic>).forEach((k, v) {
        result[k] = v.toString();
      });
      return result;
    } catch (e) {
      debugPrint('Error loading diet plan: $e');
      return null;
    }
  }

  Future<Set<String>> getSavedDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_storageKey);
      if (content == null || content.isEmpty) return {};
      
      final Map<String, dynamic> data = json.decode(content);
      return data.keys.toSet();
    } catch (e) {
      debugPrint('Error getting saved dates: $e');
      return {};
    }
  }

  String mealForTime(DateTime now) {
    final hour = now.hour;
    if (hour < 10) return 'colazione';
    if (hour < 11) return 'spuntino_ore_11';
    if (hour < 15) return 'pranzo';
    if (hour < 17) return 'spuntino_ore_17';
    if (hour < 21) return 'cena';
    return 'colazione';
  }

  static const Map<String, List<String>> _images = {
    'colazione': ['assets/imgs/colazione.png'],
    'spuntino_ore_11': ['assets/imgs/spuntino11.png'],
    'pranzo': ['assets/imgs/pranzo.png'],
    'spuntino_ore_17': ['assets/imgs/spuntino17.png'],
    'cena': ['assets/imgs/cena.png'],
  };

  String getRandomImageForMeal(String meal) {
    final list = _images[meal] ?? [];
    if (list.isEmpty) return '';
    return list[Random().nextInt(list.length)];
  }
}
