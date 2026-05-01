import 'package:flutter/material.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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

                const Text(
                  'Gestão inteligente para nutricionistas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),

                const SizedBox(height: 40),

                TextField(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                      );
                    },
                    child: const Text('Entrar', style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                    );
                  },
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
