import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Length–weight constants (W = a * L^b, L in cm, W in grams).
/// Keys are lowercase class names from the YOLO model.
const Map<String, Map<String, double>> fishLengthWeightParams = {
  'catla':   {'a': 0.0090,  'b': 3.10},
  'rohu':    {'a': 0.0047,  'b': 3.34},
  'mrigal':  {'a': 0.0087,  'b': 3.05},
  'keluthi': {'a': 0.01202, 'b': 2.96},
  'pasaa':   {'a': 0.00646, 'b': 2.97},
};

/// Estimates weight in grams using W = a * L^b  (length–weight regression).
/// Returns null if the species has no known constants.
double? estimateWeightByLength(String className, double lengthCm) {
  final key = className.toLowerCase().trim();
  final params = fishLengthWeightParams[key];
  if (params == null) return null;
  return params['a']! * math.pow(lengthCm, params['b']!);
}

class DetectionService {
  static final YOLO _yolo = YOLO(
    modelPath: 'best_float32.tflite',
    task: YOLOTask.detect,
  );

  /// Runs YOLO detection on raw image bytes.
  ///
  /// Returns a list of [YOLOResult] objects parsed from the
  /// platform channel response map.
  static Future<List<YOLOResult>> detectOnImage(Uint8List imageBytes) async {
    final result = await _yolo.predict(imageBytes);
    final detections = result['detections'] as List<dynamic>? ?? [];
    return detections
        .map((d) => YOLOResult.fromMap(d as Map<dynamic, dynamic>))
        .toList();
  }
}

class SizeEstimationService {
  static final YOLO _yolo = YOLO(
    modelPath: 'best_float32.tflite',
    task: YOLOTask.detect,
  );

  // Coin diameter in cm
  static const double coinDiameterCm = 2.5;

  /// Estimates the size of a fish relative to a reference coin.
  ///
  /// Expects the image to contain both a coin and a fish.
  /// Returns a map with 'fish', 'coin', 'fishLengthCm', and 'results'.
  static Future<Map<String, dynamic>> estimateSize(Uint8List imageBytes) async {
    final result = await _yolo.predict(imageBytes);
    final detections = result['detections'] as List<dynamic>? ?? [];
    final results = detections
        .map((d) => YOLOResult.fromMap(d as Map<dynamic, dynamic>))
        .toList();
    YOLOResult? coin;
    YOLOResult? fish;
    for (final r in results) {
      if (r.className.toLowerCase().contains('coin')) {
        coin = r;
      } else {
        fish = r;
      }
    }
    if (coin == null || fish == null) {
      throw Exception('Coin or fish not found');
    }
    final coinBox = coin.boundingBox;
    final fishBox = fish.boundingBox;

    // Coin width in pixels (scale reference)
    final coinPx = (coinBox.right - coinBox.left)
        .abs()
        .toDouble()
        .clamp(1, double.infinity);

    // Fish bounding box sides
    final fishWidthPx  = (fishBox.right - fishBox.left).abs().toDouble();
    final fishHeightPx = (fishBox.bottom - fishBox.top).abs().toDouble();

    // Length = longest side
    final fishLengthPx = [fishWidthPx, fishHeightPx]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity);

    // Scale: cm per pixel
    final scale = coinDiameterCm / coinPx;

    // Real-world length (apply tail correction)
    final fishLengthCm = fishLengthPx * scale * 0.90; // reduce tail inflation

    // Weight from length-weight regression
    final fishWeightG = estimateWeightByLength(fish.className, fishLengthCm);

    return {
      'fish': fish,
      'coin': coin,
      'fishLengthCm': fishLengthCm,
      'fishWeightG': fishWeightG,
      'results': results,
    };
  }
}

Future<File?> pickImageFromGallery() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery);
  return picked != null ? File(picked.path) : null;
}

Future<File?> pickImageFromCamera() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.camera);
  return picked != null ? File(picked.path) : null;
}
