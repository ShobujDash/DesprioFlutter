import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/settings_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.settings});

  final ApiService api;
  final SettingsService settings;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('দেশপ্রিয়'),
        actions: [
          IconButton(
            tooltip: 'API Settings',
            onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('লগইন', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Backend: ${widget.settings.baseUrl}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'ইমেইল'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'পাসওয়ার্ড'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: const Text('লগইন'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await widget.api.login(email: _emailController.text.trim(), password: _passwordController.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('লগইন করা যায়নি: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSettings() async {
    final controller = TextEditingController(text: widget.settings.baseUrl);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API URL'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Backend API URL')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ')),
          FilledButton(
            onPressed: () async {
              await widget.settings.setBaseUrl(controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }
}
