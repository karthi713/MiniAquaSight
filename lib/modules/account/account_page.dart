import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/local_storage_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _name = '';
  String _email = '';
  bool _metric = true;
  bool _pushNotifications = true;
  bool _saving = false;

  final _nameController = TextEditingController();

  String _logPath = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLogPath();
  }

  Future<void> _loadLogPath() async {
    final path = await LocalStorageService.getPredictionLogPath();
    if (!mounted) return;
    setState(() => _logPath = path);
  }

  Future<void> _loadUser() async {
    final user = await LocalStorageService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _name = user?['name'] ?? 'User';
      _email = user?['email'] ?? '';
      _nameController.text = _name;
    });
  }

  void _showLogPathDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.article_outlined, color: Colors.teal),
            SizedBox(width: 8),
            Text('Prediction Log'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Every confirmed analysis is appended to this file with timestamp, species, freshness state, size and confidence.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _logPath.isEmpty ? 'Calculating...' : _logPath,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Format per entry:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '[YYYY-MM-DD HH:MM:SS]  Species: ...  |  Freshness: ...  |  Size: ...  |  Confidence: ...%',
                style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.teal),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_logPath.isNotEmpty) {
                await Clipboard.setData(ClipboardData(text: _logPath));
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Path copied to clipboard'),
                    backgroundColor: Colors.teal),
              );
            },
            child: const Text('Copy Path'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _saving = true);
    await LocalStorageService.updateUserName(newName);
    if (!mounted) return;
    setState(() {
      _name = newName;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully'), backgroundColor: Colors.green),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocalStorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Avatar + name ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.person, size: 50, color: Colors.blue[700]),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Inspector',
                          style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Edit name ---
            _sectionLabel('Edit Display Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Your display name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Measurement Units ---
            _sectionLabel('Measurement Units'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _metric = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _metric ? Colors.blue : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Metric (cm/kg)',
                            style: TextStyle(
                              color: _metric ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _metric = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_metric ? Colors.blue : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Imperial (in/lb)',
                            style: TextStyle(
                              color: !_metric ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- General Preferences ---
            _sectionLabel('General Preferences'),
            const SizedBox(height: 8),
            _prefsCard([
              _prefTile(
                icon: Icons.language,
                iconColor: Colors.blue,
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('English', style: TextStyle(color: Colors.grey[600])),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 56),
              _prefTile(
                icon: Icons.notifications_outlined,
                iconColor: Colors.orange,
                title: 'Push Notifications',
                trailing: Switch(
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _prefTile(
                icon: Icons.location_on_outlined,
                iconColor: Colors.green,
                title: 'Location Access',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('While Using', style: TextStyle(color: Colors.grey[600])),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // --- Support ---
            _sectionLabel('Support'),
            const SizedBox(height: 8),
            _prefsCard([
              _prefTile(
                icon: Icons.help_outline,
                iconColor: Colors.deepPurple,
                title: 'Help Center',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _prefTile(
                icon: Icons.info_outline,
                iconColor: Colors.blueGrey,
                title: 'App Version',
                trailing: Text('v2.4.0', style: TextStyle(color: Colors.grey[600])),
              ),
            ]),
            const SizedBox(height: 20),

            // --- Prediction Log ---
            _sectionLabel('Prediction Log File'),
            const SizedBox(height: 8),
            _prefsCard([
              _prefTile(
                icon: Icons.article_outlined,
                iconColor: Colors.teal,
                title: 'Log File',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showLogPathDialog(),
              ),
              const Divider(height: 1, indent: 56),
              _prefTile(
                icon: Icons.copy,
                iconColor: Colors.indigo,
                title: 'Copy Path',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  if (_logPath.isEmpty) return;
                  await Clipboard.setData(ClipboardData(text: _logPath));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Log file path copied to clipboard'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 28),

            // --- Save ---
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // --- Logout ---
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 15)),
              onPressed: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));

  Widget _prefsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: children),
      );

  Widget _prefTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withAlpha(30),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
