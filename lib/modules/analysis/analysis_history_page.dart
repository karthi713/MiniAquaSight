import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

class AnalysisHistoryPage extends StatefulWidget {
  const AnalysisHistoryPage({super.key});

  @override
  State<AnalysisHistoryPage> createState() => _AnalysisHistoryPageState();
}

class _AnalysisHistoryPageState extends State<AnalysisHistoryPage> {
  List<AnalysisRecord> _all = [];
  List<AnalysisRecord> _filtered = [];
  String _search = '';
  String _filter = 'All Scans';
  bool _loading = true;

  static const _filters = ['All Scans', 'Excellent', 'Good', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalStorageService.getAnalysisHistory();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((r) {
        final matchSearch = _search.isEmpty ||
            r.fishName.toLowerCase().contains(_search.toLowerCase());
        final matchFilter = _filter == 'All Scans' ||
            r.qualityGrade.toLowerCase() == _filter.toLowerCase();
        return matchSearch && matchFilter;
      }).toList();
    });
  }

  Color _gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'excellent': return Colors.green;
      case 'good': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by day
    final grouped = <String, List<AnalysisRecord>>{};
    for (final r in _filtered) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final rDay = DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
      String label;
      if (rDay == today) {
        label = 'TODAY';
      } else if (rDay == yesterday) {
        label = 'YESTERDAY';
      } else {
        label = '${r.timestamp.day}/${r.timestamp.month}/${r.timestamp.year}';
      }
      grouped.putIfAbsent(label, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search species or batch ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (v) {
                _search = v;
                _applyFilter();
              },
            ),
          ),
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final f = _filters[i];
                final selected = _filter == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) {
                    _filter = f;
                    _applyFilter();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No analysis records yet.',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: grouped.length,
                        itemBuilder: (ctx, groupIdx) {
                          final dayLabel = grouped.keys.elementAt(groupIdx);
                          final records = grouped[dayLabel]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              ...records.map((r) => _RecordCard(record: r, gradeColor: _gradeColor(r.qualityGrade))),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AnalysisRecord record;
  final Color gradeColor;

  const _RecordCard({required this.record, required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} AM';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(
          context,
          '/history_result',
          arguments: record,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: record.imagePath != null && File(record.imagePath!).existsSync()
                ? Image.file(File(record.imagePath!), width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52,
                    height: 52,
                    color: Colors.blue[50],
                    child: Icon(Icons.set_meal, color: Colors.blue[300]),
                  ),
          ),
          title: Text(record.fishName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$timeStr • Batch #${record.id.substring(0, 4).toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              if (record.weightLabel.isNotEmpty)
                Text(record.weightLabel, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.qualityGrade.toUpperCase(),
                  style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
