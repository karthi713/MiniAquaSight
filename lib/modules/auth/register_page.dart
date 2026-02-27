import 'package:flutter/material.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';
import '../../services/local_storage_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final ok = await LocalStorageService.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() { _loading = false; _error = 'An account with this email already exists.'; });
    } else {
      setState(() { _loading = false; });
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // Google registration is not used, so remove unused method to clear warning.

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
                  Text('Dive into clarity and track your health.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person,
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Enter your name',
                  ),
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
                  const SizedBox(height: 8),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: TextStyle(color: Colors.red)),
                    ),
                  AuthButton(
                    text: _loading ? 'Signing up...' : 'Sign Up',
                    onPressed: _loading ? () {} : _register,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('or continue with', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.apple, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? '),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Log In', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
