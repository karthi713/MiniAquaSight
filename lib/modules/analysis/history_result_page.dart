import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

/// Shows the saved result for a previously analysed record from history.
class HistoryResultPage extends StatelessWidget {
  const HistoryResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final record =
        ModalRoute.of(context)?.settings.arguments as AnalysisRecord?;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No data available.')),
      );
    }

    final qualityGrade = record.qualityGrade;
    final gradeColor = qualityGrade == 'Excellent'
        ? Colors.green
        : qualityGrade == 'Good'
            ? Colors.orange
            : Colors.red;

    final imageWidget = _buildImageWidget(record.imagePath);
    final timeStr =
        '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View All History',
            onPressed: () => Navigator.popUntil(
                context, ModalRoute.withName('/history')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageWidget,
            ),
            const SizedBox(height: 8),
            // Date badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Recorded on $dateStr at $timeStr',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Identification ────────────────────────────────────
            Text('IDENTIFICATION',
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.fishName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.verified, color: Colors.green, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Confidence Score',
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 8),
                Text(
                  '${(record.confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            LinearProgressIndicator(
                value: record.confidence, minHeight: 8, color: Colors.blue),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Batch ID: ${record.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Quality Grade: $qualityGrade',
                    style: TextStyle(
                        color: gradeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Dimensions ────────────────────────────────────────
            if (record.fishLengthCm != null || record.fishWeightG != null) ...[
              Text('DIMENSIONS',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _dimensionCard(
                    'Length',
                    record.fishLengthCm != null
                        ? '${record.fishLengthCm!.toStringAsFixed(1)} cm'
                        : '--',
                  ),
                  _dimensionCard(
                    'Weight',
                    record.fishWeightG != null
                        ? (record.fishWeightG! >= 1000
                            ? '${(record.fishWeightG! / 1000).toStringAsFixed(2)} kg'
                            : '${record.fishWeightG!.toStringAsFixed(1)} g')
                        : '--',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Quality Indicators ────────────────────────────────
            Text('QUALITY INDICATORS',
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _qualityIndicator('Eye Clarity', '98%',
                'Clearness & Crystal Clear', Icons.remove_red_eye, Colors.blue),
            _qualityIndicator('Gill Color', 'Optimal',
                'Bright Red, No Mucus', Icons.color_lens, Colors.green),
            _qualityIndicator('Skin & Scales', 'Firm',
                'Moist, Shiny, Intact', Icons.texture, Colors.teal),
            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Back to History'),
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Full Analysis (Rescan)'),
              onPressed: () {
                // Navigate to detection to start a fresh full pipeline
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/detection',
                  ModalRoute.withName('/home'),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? path) {
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.set_meal, size: 64, color: Colors.blue[200]),
      ),
    );
  }
}

// Helper typedef to avoid confusion
Widget _dimensionCard(String label, String value) {
  return Expanded(
    child: Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}

Widget _qualityIndicator(
    String title, String value, String subtitle, IconData icon, Color color) {
  return Card(
    shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(value,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: color)),
    ),
  );
}
