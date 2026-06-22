import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class DietService {
  final Map<String, dynamic> _data;

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
          final label = category.replaceAll('_', ' ');
          //parts.add('$label: $item');
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

  Future<void> saveDailyMenuForDate(DateTime date, Map<String, String> menu) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/diet_plan.json');
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          data = json.decode(content) as Map<String, dynamic>;
        }
      }
      final key = date.toIso8601String().split('T').first;
      data[key] = menu;
      await file.writeAsString(json.encode(data));
    } catch (e) {
      // ignore errors silently for now
    }
  }

  Future<Map<String, String>?> loadDailyMenuForDate(DateTime date) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/diet_plan.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final data = json.decode(content) as Map<String, dynamic>;
      final key = date.toIso8601String().split('T').first;
      final menu = data[key];
      if (menu == null) return null;
      final Map<String, String> result = {};
      (menu as Map<String, dynamic>).forEach((k, v) {
        result[k] = v.toString();
      });
      return result;
    } catch (e) {
      return null;
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

  // Simple royalty-free image suggestions (Unsplash). These are remote URLs
  // and used for a more attractive UI. You may replace them as desired.
  // Use local asset images placed in `assets/imgs/`. Filenames should be
  // meaningful (e.g. colazione.png, pranzo.png, spuntino11.png, spuntino17.png).
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
