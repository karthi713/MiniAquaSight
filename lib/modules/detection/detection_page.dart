import 'package:flutter/material.dart';
import '../../services/detection_service.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});
  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  bool _loading = false;
  String? _error;

  Future<void> _detect({required bool fromCamera}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final file = fromCamera ? await pickImageFromCamera() : await pickImageFromGallery();
      if (file == null) {
        setState(() { _loading = false; });
        return;
      }
      final bytes = await file.readAsBytes();
      final results = await DetectionService.detectOnImage(bytes);
      setState(() { _loading = false; });
      Navigator.pushNamed(context, '/analysis', arguments: {
        'image': file,
        'results': results,
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fish Species Detection')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text('Choose Detection Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_loading ? 'Detecting...' : 'Live Detect (Capture)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _detect(fromCamera: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_loading ? 'Detecting...' : 'Static Detect (Upload Image)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _detect(fromCamera: false),
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
