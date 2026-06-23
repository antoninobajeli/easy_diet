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
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final svc = await DietService.loadFromAsset('assets/diet.json');
    final datesSet = await svc.getSavedDates();
    final datesList = datesSet.toList()..sort((a, b) => b.compareTo(a));

    if (!mounted) return;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadData,
        label: const Text('Aggiorna elenco'),
        icon: const Icon(Icons.sync),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedDates.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Center(child: Text('Nessun piano salvato trovato.')),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Controlla di nuovo'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _savedDates.length,
                    itemBuilder: (context, index) {
                      final dateStr = _savedDates[index];
                      final date = DateTime.parse(dateStr);
                      final formattedDate = "${date.day}/${date.month}/${date.year}";

                      return FutureBuilder<Map<String, String>?>(
                        future: _service?.loadDailyMenuForDate(date),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: ListTile(
                                title: Text(formattedDate),
                                subtitle: const Text("Caricamento..."),
                              ),
                            );
                          }
                          
                          final menu = snapshot.data;
                          if (menu == null || menu.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
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
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
      ),
    );
  }
}
