import 'package:flutter/material.dart';
import '../../services/detection_service.dart';

class SizeEstimationPage extends StatefulWidget {
  const SizeEstimationPage({super.key});
  @override
  State<SizeEstimationPage> createState() => _SizeEstimationPageState();
}

class _SizeEstimationPageState extends State<SizeEstimationPage> {
  bool _loading = false;
  String? _error;

  Future<void> _estimate({required bool fromCamera}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final file = fromCamera ? await pickImageFromCamera() : await pickImageFromGallery();
      if (file == null) {
        setState(() { _loading = false; });
        return;
      }
      final bytes = await file.readAsBytes();
      final resultMap = await SizeEstimationService.estimateSize(bytes);
      setState(() { _loading = false; });
      Navigator.pushNamed(context, '/analysis', arguments: {
        'image': file,
        'results': resultMap['results'],
        'fishLengthCm': resultMap['fishLengthCm'],
        'fishWeightG': resultMap['fishWeightG'],
        'coin': resultMap['coin'],
        'fish': resultMap['fish'],
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Size Estimation')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text('Choose Estimation Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_loading ? 'Estimating...' : 'Live Estimate (Capture)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _estimate(fromCamera: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_loading ? 'Estimating...' : 'Static Estimate (Upload Image)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _estimate(fromCamera: false),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
