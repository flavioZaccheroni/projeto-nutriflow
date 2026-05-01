import 'package:flutter/material.dart';

import '../../../../core/cloud/supabase_service.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/cloud_sync_service.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authRepository = AuthRepository();
  final _syncService = CloudSyncService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCloudEnabled = SupabaseService.isConfigured;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.health_and_safety_rounded,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'NutriFlow',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isCloudEnabled
                      ? 'Gestao inteligente com backup em nuvem'
                      : 'Gestao inteligente em modo local',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signIn,
                    child: Text(
                      _isLoading ? 'Entrando...' : 'Entrar',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: const Text('Criar conta'),
                ),
                if (!isCloudEnabled) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _openDashboard,
                    icon: const Icon(Icons.computer),
                    label: const Text('Continuar em modo local'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!SupabaseService.isConfigured) {
      _openDashboard();
      return;
    }

    await _runAuthAction(() async {
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _syncService.syncAll();
      _openDashboard();
    });
  }

  Future<void> _signUp() async {
    if (!SupabaseService.isConfigured) {
      _showMessage('Configure o Supabase para criar contas na nuvem.');
      return;
    }

    await _runAuthAction(() async {
      await _authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _syncService.syncAll();
      _openDashboard();
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      _showMessage('Informe e-mail e senha com pelo menos 6 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await action();
    } catch (error) {
      _showMessage('Falha no acesso: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
