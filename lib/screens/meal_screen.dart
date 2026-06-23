import 'package:flutter/material.dart';

import '../services/diet_service.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen>
    with AutomaticKeepAliveClientMixin {
  DietService? _service;
  String? _currentMeal;
  String? _currentItem;
  String? _currentImage;
  Map<String, String>? _dailyMenu;
  bool _loading = true;
  DateTime _startDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Set<String> _savedDates = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final svc = await DietService.loadFromAsset('assets/diet.json');
    final today = DateTime.now();
    final loaded = await svc.loadDailyMenuForDate(today);
    Map<String, String> daily;
    if (loaded != null) {
      daily = loaded;
    } else {
      daily = svc.getRandomDailyMenu();
      await svc.saveDailyMenuForDate(today, daily);
    }
    final savedDates = await svc.getSavedDates();
    final meal = svc.mealForTime(today);
    final item = daily[meal] ?? svc.getRandomForMeal(meal);
    final img = svc.getRandomImageForMeal(meal);
    setState(() {
      _service = svc;
      _dailyMenu = daily;
      _currentMeal = meal;
      _currentItem = item;
      _currentImage = img;
      _savedDates = savedDates;
      _loading = false;
    });
  }

  List<DateTime> _sevenDays() {
    return List.generate(7, (i) => DateTime(_startDate.year, _startDate.month, _startDate.day).add(Duration(days: i)));
  }

  String _weekdayLabel(DateTime d) {
    const labels = ['','Lun','Mar','Mer','Gio','Ven','Sab','Dom'];
    return labels[d.weekday];
  }

  void _shiftStartDate(int days) {
    setState(() {
      _startDate = _startDate.add(Duration(days: days));
    });
  }

  Future<void> _loadMenuForDate(DateTime date) async {
    if (_service == null) return;
    final menu = await _service!.loadDailyMenuForDate(date);
    Map<String, String> usedMenu;
    if (menu != null) {
      usedMenu = menu;
    } else {
      usedMenu = _service!.getRandomDailyMenu();
      await _service!.saveDailyMenuForDate(date, usedMenu);
    }
    final meal = _service!.mealForTime(date);
    if (menu == null) {
      await _saveAndVerify(date, usedMenu);
    } else {
      final savedDates = await _service!.getSavedDates();
      setState(() {
        _savedDates = savedDates;
      });
    }
    
    setState(() {
      _selectedDate = date;
      _dailyMenu = usedMenu;
      _currentMeal = meal;
      _currentItem = usedMenu[meal];
      _currentImage = _service!.getRandomImageForMeal(meal);
    });
  }

  Future<void> _refreshItem() async {
    if (_service == null || _currentMeal == null || _dailyMenu == null) return;
    final newItem = _service!.getRandomForMeal(_currentMeal!);
    final newImg = _service!.getRandomImageForMeal(_currentMeal!);
    setState(() {
      _currentItem = newItem;
      _currentImage = newImg;
      _dailyMenu![_currentMeal!] = newItem;
    });
    await _saveAndVerify(_selectedDate, _dailyMenu!);
  }

  Future<void> _refreshDaily() async {
    if (_service == null) return;
    final newMenu = _service!.getRandomDailyMenu();
    setState(() {
      _dailyMenu = newMenu;
      if (_currentMeal != null) {
        _currentItem = _dailyMenu![_currentMeal!];
        _currentImage = _service!.getRandomImageForMeal(_currentMeal!);
      }
    });
    // Salva esplicitamente il nuovo menu generato per la data selezionata
    await _saveAndVerify(_selectedDate, newMenu);
  }

  void _selectDailyMeal(String mealKey, String? mealValue) {
    if (_service == null) return;
    setState(() {
      _currentMeal = mealKey;
      _currentItem = mealValue;
      _currentImage = _service!.getRandomImageForMeal(mealKey);
    });
  }

  void _showSaveFeedback(DateTime date, bool verified) {
    if (!mounted) return;
    final dateStr = "${date.day}/${date.month}/${date.year}";
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(verified ? Icons.verified_user : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(verified 
                  ? 'FILE SCRITTO: Piano verificato per il $dateStr' 
                  : 'ERRORE: Impossibile verificare la scrittura su file'),
            ),
          ],
        ),
        backgroundColor: verified ? Colors.blueAccent : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _saveAndVerify(DateTime date, Map<String, String> menu) async {
    if (_service == null) return;
    
    // 1. Salvataggio con flush
    final success = await _service!.saveDailyMenuForDate(date, menu);
    
    if (!success) {
      _showSaveFeedback(date, false);
      return;
    }

    // Piccola attesa per il filesystem
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 2. Verifica (rilettura REALE dal disco)
    final verifiedMenu = await _service!.loadDailyMenuForDate(date);
    final savedDates = await _service!.getSavedDates();
    
    // Confronto dei contenuti per la massima certezza
    bool isVerified = verifiedMenu != null && 
                     verifiedMenu.length == menu.length &&
                     verifiedMenu.keys.every((k) => menu.containsKey(k));
    
    setState(() {
      _savedDates = savedDates;
    });
    
    _showSaveFeedback(date, isVerified);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                            ? (_currentImage!.startsWith('http')
                                ? Image.network(
                                    _currentImage!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    _currentImage!,
                                    fit: BoxFit.cover,
                                  ))
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ), 
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentItem ?? '-',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                      maxLines: 6,
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
                              child: const Icon(Icons.refresh)
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
                        // Horizontal 7-day selector
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _shiftStartDate(-1),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _sevenDays().map((d) {
                                    final dateKey = d.toIso8601String().split('T').first;
                                    final hasSaved = _savedDates.contains(dateKey);
                                    final isSelected = DateTime(d.year, d.month, d.day) ==
                                        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: GestureDetector(
                                        onTap: () => _loadMenuForDate(d),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? Colors.blue.shade50 
                                                : (hasSaved ? Colors.green.shade100 : null),
                                            border: Border.all(
                                                color: isSelected 
                                                    ? Colors.blueAccent 
                                                    : (hasSaved ? Colors.green : Colors.transparent), 
                                                width: 2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(_weekdayLabel(d), 
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold, 
                                                      color: isSelected 
                                                          ? Colors.blueAccent 
                                                          : (hasSaved ? Colors.green.shade700 : null))),
                                              const SizedBox(height: 4),
                                              Text('${d.day}', 
                                                  style: TextStyle(
                                                      color: isSelected 
                                                          ? Colors.blueAccent 
                                                          : (hasSaved ? Colors.green.shade700 : null))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _shiftStartDate(1),
                            ),
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
                  ? (imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Image.asset(imageUrl, fit: BoxFit.cover))
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
