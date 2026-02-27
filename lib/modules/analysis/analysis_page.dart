import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _saved = false;
  bool _saving = false;

  String _generateId() {
    final rng = Random();
    return '${DateTime.now().millisecondsSinceEpoch}${rng.nextInt(9999)}';
  }

  Future<void> _confirmAndSave(Map args) async {
    if (_saved) {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
      return;
    }
    setState(() => _saving = true);

    final image = args['image'];
    final results = args['results'];
    final fishLengthCm = args['fishLengthCm'];
    final fishWeightG = args['fishWeightG'];
    final fishObj = args['fish'];

    String fishName = 'Unknown';
    double confidence = 0.0;
    if (results != null && (results as List).isNotEmpty) {
      final main = fishObj ?? results[0];
      fishName = main.className ?? 'Unknown';
      confidence = (main.confidence ?? 0.0).toDouble();
    }

    final record = AnalysisRecord(
      id: _generateId(),
      fishName: fishName,
      confidence: confidence,
      fishLengthCm: fishLengthCm?.toDouble(),
      fishWeightG: fishWeightG?.toDouble(),
      imagePath: image?.path,
      timestamp: DateTime.now(),
      qualityGrade: confidence >= 0.85 ? 'Excellent' : confidence >= 0.6 ? 'Good' : 'Rejected',
    );

    await LocalStorageService.saveAnalysis(record);
    await LocalStorageService.appendPredictionLog(record);
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analysis saved to history & log file!'), backgroundColor: Colors.green),
    );
    Navigator.popUntil(context, ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final image = args != null ? args['image'] : null;
    final results = args != null ? args['results'] : null;
    final fishLengthCm = args != null ? args['fishLengthCm'] : null;
    final fishWeightG = args != null ? args['fishWeightG'] : null;
    final fish = args != null ? args['fish'] : null;

    String fishName = 'Unknown';
    String scientificName = '';
    double confidence = 0.0;
    if (results != null && (results as List).isNotEmpty) {
      final main = fish ?? results[0];
      fishName = main.className ?? 'Unknown';
      confidence = (main.confidence ?? 0.0).toDouble();
      scientificName = '';
    }

    final qualityGrade =
        confidence >= 0.85 ? 'Excellent' : confidence >= 0.6 ? 'Good' : 'Rejected';
    final gradeColor =
        qualityGrade == 'Excellent' ? Colors.green : qualityGrade == 'Good' ? Colors.orange : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('No Image')),
              ),
            const SizedBox(height: 24),
            Text('IDENTIFICATION', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fishName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (scientificName.isNotEmpty)
                        Text(scientificName, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: Colors.green, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Confidence Score', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 8),
                Text('${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            LinearProgressIndicator(value: confidence, minHeight: 8, color: Colors.blue),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Batch ID: AUTO', style: TextStyle(color: Colors.grey[700]))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Quality Grade: $qualityGrade',
                      style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fishLengthCm != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.straighten, color: Colors.blue),
                  title: const Text('Estimated Fish Length'),
                  subtitle: Text('${fishLengthCm.toStringAsFixed(1)} cm'),
                ),
              ),
            if (fishWeightG != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight, color: Colors.deepPurple),
                  title: const Text('Estimated Weight'),
                  subtitle: Text(fishWeightG >= 1000
                      ? '${(fishWeightG / 1000).toStringAsFixed(2)} kg'
                      : '${fishWeightG.toStringAsFixed(1)} g'),
                ),
              ),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blue),
                title: Text('Standard Reference'),
                subtitle: Text(
                    'Characterized by small black spots, mostly above the lateral line. Caudal fin is usually unspotted.'),
              ),
            ),
            const SizedBox(height: 24),
            Text('DIMENSIONS',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _dimensionCard('Length',
                    fishLengthCm != null ? '${fishLengthCm.toStringAsFixed(1)} cm' : '--'),
                _dimensionCard(
                    'Weight',
                    fishWeightG != null
                        ? (fishWeightG >= 1000
                            ? '${(fishWeightG / 1000).toStringAsFixed(2)} kg'
                            : '${fishWeightG.toStringAsFixed(1)} g')
                        : '--'),
              ],
            ),
            const SizedBox(height: 24),
            Text('QUALITY INDICATORS',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _qualityIndicator('Eye Clarity', '98%', 'Clearness & Crystal Clear',
                Icons.remove_red_eye, Colors.blue),
            _qualityIndicator('Gill Color', 'Optimal', 'Bright Red, No Mucus',
                Icons.color_lens, Colors.green),
            _qualityIndicator('Skin & Scales', 'Firm', 'Moist, Shiny, Intact',
                Icons.texture, Colors.teal),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download PDF Report'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () { if (args != null) _confirmAndSave(args); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_saved ? 'Saved ✓' : 'Confirm & Save Result'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Re-scan Image'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _dimensionCard(String label, String value) {
  return Expanded(
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}

Widget _qualityIndicator(String title, String value, String subtitle,
    IconData icon, Color color) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ),
  );
}
