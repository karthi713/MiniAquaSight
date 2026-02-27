import 'package:flutter/material.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';
import '../../services/local_storage_service.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.water_drop, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text('AquaSight', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Precision fish analysis and quality tracking for the modern industry',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email,
                    validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                  ),
                  AuthTextField(
                    label: 'Password',
                    controller: _passwordController,
                    isPassword: true,
                    icon: Icons.lock,
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: TextStyle(color: Colors.red)),
                    ),
                  AuthButton(
                    text: _loading ? 'Logging in...' : 'Log In',
                    onPressed: _loading ? () {} : _login,
                  ),
                  const SizedBox(height: 8),
                  AuthButton(
                    text: 'Create Account',
                    isPrimary: false,
                    onPressed: _loading ? () {} : () {
                      Navigator.pushNamed(context, '/register');
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('or continue with', style: TextStyle(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Apple sign-in not available',
                        child: IconButton(
                          icon: Icon(Icons.apple, size: 28, color: Colors.grey[400]),
                          onPressed: _loading ? null : _showAppleNotAvailable,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Tooltip(
                        message: 'Sign in with Google',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _loading ? null : _loginWithGoogle,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.g_mobiledata, size: 26, color: Colors.red[600]),
                                const SizedBox(width: 4),
                                const Text('Google', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('QUALITY GUARANTEED', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('By logging in, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final user = await LocalStorageService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (user == null) {
      setState(() { _loading = false; _error = 'Invalid email or password.'; });
    } else {
      setState(() { _loading = false; });
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showAppleNotAvailable() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.apple, color: Colors.grey[700]),
            const SizedBox(width: 8),
            const Text('Apple Sign-In'),
          ],
        ),
        content: const Text(
          'Apple sign-in is not supported on this platform.\n\nPlease use your email and password, or sign in with Google.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Not Available'),
          ],
        ),
        content: const Text(
          'Social sign-in (Google / Apple) is not available in offline mode.\n\nPlease use your email and password to log in, or create an account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _loginWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isCancelled = msg.contains('cancelled') || msg.contains('cancel');
      setState(() {
        _loading = false;
        _error = isCancelled ? null : 'Google sign-in failed. Please try again.';
      });
    }
  }
}
