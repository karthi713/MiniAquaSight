import 'package:flutter/material.dart';

class FreshnessPage extends StatelessWidget {
  const FreshnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Freshness Detection')),
      body: const Center(
        child: Text('Freshness detection coming soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
