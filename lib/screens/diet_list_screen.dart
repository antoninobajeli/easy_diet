import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class DietListScreen extends StatefulWidget {
  const DietListScreen({super.key});

  @override
  State<DietListScreen> createState() => _DietListScreenState();
}

class _DietListScreenState extends State<DietListScreen> {
  Map<String, dynamic>? _dietData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDietData();
  }

  Future<void> _loadDietData() async {
    try {
      final String response = await rootBundle.loadString('assets/diet.json');
      final data = await json.decode(response);
      setState(() {
        _dietData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutte le opzioni'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dietData == null
              ? const Center(child: Text('Errore nel caricamento dei dati'))
              : ListView.builder(
                  itemCount: _dietData!.keys.length,
                  itemBuilder: (context, index) {
                    final mealKey = _dietData!.keys.elementAt(index);
                    final mealData = _dietData![mealKey] as Map<String, dynamic>;
                    
                    return ExpansionTile(
                      title: Text(
                        mealKey.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: mealData.entries.map((entry) {
                        final category = entry.key;
                        final items = entry.value as List<dynamic>;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(child: Text(item.toString())),
                                      ],
                                    ),
                                  )),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
    );
  }
}
