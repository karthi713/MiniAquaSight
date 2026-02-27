import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'modules/auth/login_page.dart' show LoginPage;
import 'modules/auth/register_page.dart';
import 'modules/detection/detection_page.dart';
import 'modules/detection/size_estimation_page.dart';
import 'modules/detection/full_analysis_page.dart';
import 'modules/analysis/analysis_page.dart';
import 'modules/analysis/freshness_page.dart';
import 'modules/analysis/analysis_history_page.dart';
import 'modules/analysis/history_result_page.dart';
import 'modules/account/account_page.dart';
import 'services/local_storage_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaSight',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/detection': (context) => const DetectionPage(),
        '/size': (context) => const SizeEstimationPage(),
        '/full_analysis': (context) => const FullAnalysisPage(),
        '/freshness': (context) => const FreshnessPage(),
        '/analysis': (context) => const AnalysisPage(),
        '/history': (context) => const AnalysisHistoryPage(),
        '/history_result': (context) => const HistoryResultPage(),
        '/account': (context) => const AccountPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 1; // 0=History, 1=Home/Camera, 2=Stats
  String _userName = '';
  List<AnalysisRecord> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final user = await LocalStorageService.getCurrentUser();
    final recent = await LocalStorageService.getRecentAnalysis(limit: 4);
    if (!mounted) return;
    setState(() {
      _userName = user?['name'] ?? 'Captain';
      _recent = recent;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('AquaSight',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.pushNamed(context, '/account');
              _load(); // refresh name if updated
            },
          ),
        ],
      ),
      body: _navIndex == 0
          ? const AnalysisHistoryPage()
          : _navIndex == 2
              ? const _StatsPlaceholder()
              : _homeBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: Icon(Icons.camera_alt, color: Colors.white),
            ),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }

  Widget _homeBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/size'),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.straighten, color: Colors.blue, size: 32),
                            const SizedBox(height: 8),
                            const Text('Size',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Calibrate & measure length',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/detection'),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.search, color: Colors.blue, size: 32),
                            const SizedBox(height: 8),
                            const Text('Species',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Identify 50+ varieties',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/freshness'),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Freshness Detection',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Scan eyes and gills for quality grade',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Full Analysis button ──────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/full_analysis'),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined,
                          color: Colors.blue, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Full Analysis',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'Species ID + Size + Freshness in one scan',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Analysis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No scans yet. Start your first analysis!',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recent.length,
                itemBuilder: (ctx, i) {
                  final r = _recent[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: r.imagePath != null &&
                                File(r.imagePath!).existsSync()
                            ? Image.file(File(r.imagePath!),
                                width: 48, height: 48, fit: BoxFit.cover)
                            : Container(
                                width: 48,
                                height: 48,
                                color: Colors.blue[50],
                                child: Icon(Icons.set_meal,
                                    color: Colors.blue[300])),
                      ),
                      title: Text(r.fishName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${r.qualityGrade}  •  ${r.weightLabel.isNotEmpty ? r.weightLabel : r.timeLabel}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gradeColor(r.qualityGrade).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.qualityGrade.toUpperCase(),
                          style: TextStyle(
                              color: _gradeColor(r.qualityGrade),
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(
                          context, '/history_result', arguments: r),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsPlaceholder extends StatelessWidget {
  const _StatsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Stats coming soon',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}


// ...existing code...




// ...existing code...
// LOGIN/SIGNUP SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLogin = true;

  void _submit() {
    // Accept any text and go in
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.water_drop, size: 56, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'AquaSight',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Precision fish analysis for the modern industry',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => email = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onChanged: (v) => password = v,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(isLogin ? 'Log In' : 'Sign Up'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                        child: Text(isLogin
                            ? 'Create Account'
                            : 'Already have an account? Log In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'QUALITY GUARANTEED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 AquaSight',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// DASHBOARD SCREEN
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Hello, karthi!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Ready for today\'s catch?', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blue),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue, size: 36),
                title: const Text('Species Identification', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Identify fish species instantly'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraScreen()),
                    );
                  },
                  child: const Text('Open Camera'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Available Fishes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FishCard(name: 'Keluthi'),
                _FishCard(name: 'Pasaa'),
                _FishCard(name: 'Mirugal'),
                _FishCard(name: 'Rohu Catla'),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.eco, color: Colors.green, size: 36),
                title: const Text('Freshness Detection'),
                subtitle: const Text('Check freshness (coming soon)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.straighten, color: Colors.deepPurple, size: 36),
                title: const Text('Size Measurement'),
                subtitle: const Text('Measure fish size (coming soon)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FishCard extends StatelessWidget {
  final String name;
  const _FishCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha((0.04 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    );
  }
}

// CAMERA SCREEN WITH REAL YOLO
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // TODO: Implement YOLOView or use a placeholder widget here.
      body: Center(child: Text('Camera/YOLOView not implemented.')),
    );
  }
}

// RESULT PAGE
class ResultScreen extends StatelessWidget {
  final File image;
  final dynamic detection;
  const ResultScreen({required this.image, required this.detection, super.key});

  @override
  Widget build(BuildContext context) {
    // Try to extract bounding box and class index from detection
    final box = detection.boundingBox ?? detection['boundingBox'] ?? detection['box'] ?? Rect.zero;
    final classIndex = detection.classIndex ?? detection['classIndex'] ?? detection['class'] ?? 0;
    final species = _getSpeciesName(classIndex);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text('Analysis Result', style: TextStyle(color: Colors.blue)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    image,
                    width: 320,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: box.left,
                  top: box.top,
                  child: Container(
                    width: box.width,
                    height: box.height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('FRESH', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Text(
                  species,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Confidence: 98%'),
                        SizedBox(width: 16),
                        Icon(Icons.timer, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Processed: ~2h'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Analysis Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.remove_red_eye, color: Colors.blue, size: 18),
                        SizedBox(width: 4),
                        Text('Eye Clarity: Bright'),
                        SizedBox(width: 16),
                        Icon(Icons.color_lens, color: Colors.deepPurple, size: 18),
                        SizedBox(width: 4),
                        Text('Gill Color: Bright Pink'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.straighten, color: Colors.deepPurple, size: 18),
                        SizedBox(width: 4),
                        Text('Size: 1.2 kg'),
                        SizedBox(width: 16),
                        Icon(Icons.straighten, color: Colors.blue, size: 18),
                        SizedBox(width: 4),
                        Text('Length: 45 cm'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Save to Inventory'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Analyze Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _getSpeciesName(int classIndex) {
  // Map your YOLO class indices to fish names
  switch (classIndex) {
    case 0:
      return 'Keluthi';
    case 1:
      return 'Pasaa';
    case 2:
      return 'Mirugal';
    case 3:
      return 'Rohu Catla';
    default:
      return 'Unknown';
  }
}
