import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used in SharedPreferences
const _kUsers = 'aq_users';
const _kCurrentEmail = 'aq_current_email';
const _kCurrentName = 'aq_current_name';
const _kAnalysisHistory = 'aq_analysis_history';

// ---------------------------------------------------------------------------
// User model
// ---------------------------------------------------------------------------

class AppUser {
  final String name;
  final String email;
  final String password;

  const AppUser({required this.name, required this.email, required this.password});

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'password': password};

  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(name: j['name'], email: j['email'], password: j['password']);
}

// ---------------------------------------------------------------------------
// Analysis record model
// ---------------------------------------------------------------------------

class AnalysisRecord {
  final String id;
  final String fishName;
  final double confidence;
  final double? fishLengthCm;
  final double? fishWeightG;
  final String? imagePath;
  final DateTime timestamp;
  final String qualityGrade;

  const AnalysisRecord({
    required this.id,
    required this.fishName,
    required this.confidence,
    this.fishLengthCm,
    this.fishWeightG,
    this.imagePath,
    required this.timestamp,
    required this.qualityGrade,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fishName': fishName,
        'confidence': confidence,
        'fishLengthCm': fishLengthCm,
        'fishWeightG': fishWeightG,
        'imagePath': imagePath,
        'timestamp': timestamp.toIso8601String(),
        'qualityGrade': qualityGrade,
      };

  factory AnalysisRecord.fromJson(Map<String, dynamic> j) => AnalysisRecord(
        id: j['id'] as String,
        fishName: j['fishName'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        fishLengthCm: j['fishLengthCm'] != null ? (j['fishLengthCm'] as num).toDouble() : null,
        fishWeightG: j['fishWeightG'] != null ? (j['fishWeightG'] as num).toDouble() : null,
        imagePath: j['imagePath'] as String?,
        timestamp: DateTime.parse(j['timestamp'] as String),
        qualityGrade: j['qualityGrade'] as String,
      );

  /// Short description for list tiles.
  String get weightLabel {
    if (fishWeightG == null) return '';
    if (fishWeightG! >= 1000) return '${(fishWeightG! / 1000).toStringAsFixed(2)} kg';
    return '${fishWeightG!.toStringAsFixed(1)} g';
  }

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class LocalStorageService {
  // ---------- USER REGISTRATION ----------

  /// Register a new user. Returns false if email already exists.
  static Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return false; // already registered
    }
    users.add(AppUser(name: name, email: email, password: password));
    await _saveUsers(prefs, users);
    // Auto-set as current session
    await prefs.setString(_kCurrentEmail, email);
    await prefs.setString(_kCurrentName, name);
    return true;
  }

  // ---------- LOGIN ----------

  /// Validates credentials. Returns the user on success, null on failure.
  static Future<AppUser?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    try {
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password,
      );
      await prefs.setString(_kCurrentEmail, user.email);
      await prefs.setString(_kCurrentName, user.name);
      return user;
    } catch (_) {
      return null;
    }
  }

  // ---------- SESSION ----------

  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kCurrentEmail);
    final name = prefs.getString(_kCurrentName);
    if (email == null || name == null) return null;
    return {'email': email, 'name': name};
  }

  static Future<void> updateUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kCurrentEmail);
    if (email == null) return;

    // Update in user list
    final users = _loadUsers(prefs);
    final idx = users.indexWhere((u) => u.email.toLowerCase() == email.toLowerCase());
    if (idx != -1) {
      final old = users[idx];
      users[idx] = AppUser(name: newName, email: old.email, password: old.password);
      await _saveUsers(prefs, users);
    }
    await prefs.setString(_kCurrentName, newName);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentEmail);
    await prefs.remove(_kCurrentName);
  }

  /// Directly sets the current session (used for OAuth sign-in flows where
  /// there is no password).
  static Future<void> forceSession({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentEmail, email);
    await prefs.setString(_kCurrentName, name);
  }

  // ---------- ANALYSIS HISTORY ----------

  /// Prepends the record; keeps latest 50.
  static Future<void> saveAnalysis(AnalysisRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadHistory(prefs);
    list.insert(0, record);
    if (list.length > 50) list.removeRange(50, list.length);
    await prefs.setString(_kAnalysisHistory, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  /// Returns full history, most recent first.
  static Future<List<AnalysisRecord>> getAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadHistory(prefs);
  }

  /// Returns the N most recent records.
  static Future<List<AnalysisRecord>> getRecentAnalysis({int limit = 4}) async {
    final all = await getAnalysisHistory();
    return all.take(limit).toList();
  }

  // ---------- PREDICTION LOG FILE ----------

  /// Appends one prediction entry to `aquasight_predictions.txt` in the
  /// app's documents directory.  Creates the file if it doesn't exist yet.
  static Future<File> appendPredictionLog(AnalysisRecord record) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aquasight_predictions.txt');

    // ── build the log line ──────────────────────────────────────
    final ts = record.timestamp;
    final tsStr =
        '${ts.year}-${_pad(ts.month)}-${_pad(ts.day)} '
        '${_pad(ts.hour)}:${_pad(ts.minute)}:${_pad(ts.second)}';

    String sizeStr = 'N/A';
    if (record.fishLengthCm != null && record.fishWeightG != null) {
      final wLabel = record.fishWeightG! >= 1000
          ? '${(record.fishWeightG! / 1000).toStringAsFixed(2)} kg'
          : '${record.fishWeightG!.toStringAsFixed(1)} g';
      sizeStr = '${record.fishLengthCm!.toStringAsFixed(1)} cm / $wLabel';
    } else if (record.fishLengthCm != null) {
      sizeStr = '${record.fishLengthCm!.toStringAsFixed(1)} cm';
    } else if (record.fishWeightG != null) {
      sizeStr = record.weightLabel;
    }

    final line =
        '[$tsStr]  '
        'Species: ${record.fishName}  |  '
        'Freshness: ${record.qualityGrade}  |  '
        'Size: $sizeStr  |  '
        'Confidence: ${(record.confidence * 100).toStringAsFixed(1)}%';

    // ── write header on first use ───────────────────────────────
    if (!file.existsSync()) {
      await file.writeAsString(
        'AquaSight Prediction Log\n'
        '========================\n\n',
      );
    }

    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    return file;
  }

  /// Returns the path of the prediction log file (may not exist yet).
  static Future<String> getPredictionLogPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/aquasight_predictions.txt';
  }

  // ---------- HELPERS ----------

  static String _pad(int v) => v.toString().padLeft(2, '0');

  static List<AppUser> _loadUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_kUsers);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _saveUsers(SharedPreferences prefs, List<AppUser> users) async {
    await prefs.setString(_kUsers, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  static List<AnalysisRecord> _loadHistory(SharedPreferences prefs) {
    final raw = prefs.getString(_kAnalysisHistory);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => AnalysisRecord.fromJson(e as Map<String, dynamic>)).toList();
  }
}
