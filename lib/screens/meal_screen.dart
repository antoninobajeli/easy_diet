import 'package:flutter/material.dart';

import '../services/diet_service.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  DietService? _service;
  String? _currentMeal;
  String? _currentItem;
  String? _currentImage;
  Map<String, String>? _dailyMenu;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final svc = await DietService.loadFromAsset('assets/diet.json');
    final daily = svc.getRandomDailyMenu();
    final meal = svc.mealForTime(DateTime.now());
    final item = svc.getRandomForMeal(meal);
    final img = svc.getRandomImageForMeal(meal);
    setState(() {
      _service = svc;
      _dailyMenu = daily;
      _currentMeal = meal;
      _currentItem = item;
      _currentImage = img;
      _loading = false;
    });
  }

  void _refreshItem() {
    if (_service == null || _currentMeal == null) return;
    setState(() {
      _currentItem = _service!.getRandomForMeal(_currentMeal!);
      _currentImage = _service!.getRandomImageForMeal(_currentMeal!);
    });
  }

  void _refreshDaily() {
    if (_service == null) return;
    setState(() {
      _dailyMenu = _service!.getRandomDailyMenu();
      _currentItem = _dailyMenu![_currentMeal!];
      _currentImage = _service!.getRandomImageForMeal(_currentMeal!);
    });
  }

  void _selectDailyMeal(String mealKey, String? mealValue) {
    if (_service == null) return;
    setState(() {
      _currentMeal = mealKey;
      _currentItem = mealValue;
      _currentImage = _service!.getRandomImageForMeal(mealKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Diet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: _currentImage != null && _currentImage!.isNotEmpty
                            ? Image.network(
                                _currentImage!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: Colors.grey[300]),
                      ),
                      Container(
                        height: 260,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentMeal?.toUpperCase() ?? '-',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentItem ?? '-',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _refreshItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white70,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Altro'),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Menu giornaliero',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _refreshDaily,
                              child: const Text('Rigenera menu'),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_dailyMenu != null) ...[
                          _buildMiniCard('Colazione', 'colazione', _dailyMenu!['colazione'], _service!.getRandomImageForMeal('colazione')),
                          const SizedBox(height: 8),
                          _buildMiniCard('Spuntino 11', 'spuntino_ore_11', _dailyMenu!['spuntino_ore_11'], _service!.getRandomImageForMeal('spuntino_ore_11')),
                          const SizedBox(height: 8),
                          _buildMiniCard('Pranzo', 'pranzo', _dailyMenu!['pranzo'], _service!.getRandomImageForMeal('pranzo')),
                          const SizedBox(height: 8),
                          _buildMiniCard('Spuntino 17', 'spuntino_ore_17', _dailyMenu!['spuntino_ore_17'], _service!.getRandomImageForMeal('spuntino_ore_17')),
                          const SizedBox(height: 8),
                          _buildMiniCard('Cena', 'cena', _dailyMenu!['cena'], _service!.getRandomImageForMeal('cena')),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildMiniCard(String title, String mealKey, String? subtitle, String imageUrl) {
    final isSelected = mealKey == _currentMeal;
    return Card(
      clipBehavior: Clip.hardEdge,
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectDailyMeal(mealKey, subtitle),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 72,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
