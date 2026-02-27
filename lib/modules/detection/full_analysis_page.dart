import 'package:flutter/material.dart';
import '../../services/detection_service.dart';

/// Full Analysis page — runs Species Detection + Size Estimation in one flow,
/// then navigates to the Analysis Results page with all combined data.
class FullAnalysisPage extends StatefulWidget {
  const FullAnalysisPage({super.key});

  @override
  State<FullAnalysisPage> createState() => _FullAnalysisPageState();
}

class _FullAnalysisPageState extends State<FullAnalysisPage> {
  bool _loading = false;
  String? _error;

  Future<void> _start({required bool fromCamera}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final file = fromCamera
          ? await pickImageFromCamera()
          : await pickImageFromGallery();

      if (file == null) {
        setState(() { _loading = false; });
        return;
      }

      final bytes = await file.readAsBytes();

      Map<String, dynamic>? sizeResult;
      List<dynamic>? detectionResults;
      dynamic bestFish;
      double? fishLengthCm;
      double? fishWeightG;

      try {
        sizeResult = await SizeEstimationService.estimateSize(bytes);
        bestFish = sizeResult['fish'];
        fishLengthCm = (sizeResult['fishLengthCm'] as num?)?.toDouble();
        fishWeightG = (sizeResult['fishWeightG'] as num?)?.toDouble();
        detectionResults = (sizeResult['results'] as List<dynamic>?) ?? [];
      } catch (_) {
        detectionResults = await DetectionService.detectOnImage(bytes);
        if (detectionResults.isNotEmpty) {
          bestFish = detectionResults.first;
        }
      }

      setState(() { _loading = false; });
      if (!mounted) return;

      Navigator.pushNamed(context, '/analysis', arguments: {
        'image': file,
        'results': detectionResults,
        'fish': bestFish,
        'fishLengthCm': fishLengthCm,
        'fishWeightG': fishWeightG,
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text('Choose Detection Mode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_loading ? 'Analysing...' : 'Live Detect (Capture)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _start(fromCamera: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_loading ? 'Analysing...' : 'Static Detect (Upload Image)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _start(fromCamera: false),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

