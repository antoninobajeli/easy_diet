import 'package:flutter/material.dart';
import '../services/diet_service.dart';

class SavedPlansScreen extends StatefulWidget {
  const SavedPlansScreen({super.key});

  @override
  State<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends State<SavedPlansScreen> {
  DietService? _service;
  List<String> _savedDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final svc = await DietService.loadFromAsset('assets/diet.json');
    final datesSet = await svc.getSavedDates();
    final datesList = datesSet.toList()..sort((a, b) => b.compareTo(a)); // Ordine decrescente

    setState(() {
      _service = svc;
      _savedDates = datesList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piani Salvati'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedDates.isEmpty
              ? const Center(child: Text('Nessun piano salvato trovato.'))
              : ListView.builder(
                  itemCount: _savedDates.length,
                  itemBuilder: (context, index) {
                    final dateStr = _savedDates[index];
                    final date = DateTime.parse(dateStr);
                    final formattedDate = "${date.day}/${date.month}/${date.year}";

                    return FutureBuilder<Map<String, String>?>(
                      future: _service?.loadDailyMenuForDate(date),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox.shrink();
                        }
                        final menu = snapshot.data!;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ExpansionTile(
                            title: Text(
                              formattedDate,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("${menu.length} pasti registrati"),
                            children: menu.entries.map((entry) {
                              return ListTile(
                                title: Text(
                                  entry.key.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(entry.value),
                                dense: true,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
