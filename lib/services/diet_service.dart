import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class DietService {
  final Map<String, dynamic> _data;

  DietService._(this._data);

  static Future<DietService> loadFromAsset(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    return DietService._(data);
  }

  List<String> _flattenMeal(String meal) {
    final mealMap = _data[meal] as Map<String, dynamic>?;
    if (mealMap == null) return [];
    final List<String> items = [];
    mealMap.forEach((_, value) {
      if (value is List) items.addAll(value.map((e) => e.toString()));
    });
    return items;
  }

  String getRandomForMeal(String meal) {
    final items = _flattenMeal(meal);
    if (items.isEmpty) return 'Nessun elemento disponibile';
    return items[Random().nextInt(items.length)];
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
  static const Map<String, List<String>> _images = {
    'colazione': [
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1505575967450-4b9f0b6d9d2b?auto=format&fit=crop&w=800&q=80'
    ],
    'spuntino_ore_11': [
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1505575967450-4b9f0b6d9d2b?auto=format&fit=crop&w=800&q=80'
    ],
    'pranzo': [
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80'
    ],
    'spuntino_ore_17': [
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80'
    ],
    'cena': [
      'https://images.unsplash.com/photo-1543352634-1b5c4d56c3b8?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80'
    ],
  };

  String getRandomImageForMeal(String meal) {
    final list = _images[meal] ?? [];
    if (list.isEmpty) return '';
    return list[Random().nextInt(list.length)];
  }
}
