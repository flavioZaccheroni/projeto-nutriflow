import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/models/history_event_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../data/repositories/meal_plan_repository.dart';
import '../../../../data/repositories/patient_repository.dart';
import '../../../../data/services/cloud_sync_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../foods/presentation/pages/food_database_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../meal_plans/presentation/pages/meal_plan_patient_select_page.dart';
import '../../../patients/presentation/pages/patient_form_page.dart';
import '../../../patients/presentation/pages/patient_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authRepository = AuthRepository();
  final _syncService = CloudSyncService();
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            tooltip: 'Sincronizar nuvem',
            onPressed: _isSyncing ? null : _syncCloud,
            icon: Icon(_isSyncing ? Icons.sync : Icons.cloud_sync_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: Responsive.contentMaxWidth(context),
        child: ListView(
          padding: Responsive.pagePadding(context),
          children: [
            const Text(
              'Bem-vindo ao NutriFlow',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gerencie seus pacientes e planos alimentares.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: Responsive.dashboardColumns(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: Responsive.isMobile(context) ? 2.6 : 1.45,
              children: [
                StreamBuilder<List<PatientModel>>(
                  stream: PatientRepository().watchAll(),
                  builder: (context, snapshot) {
                    return DashboardCard(
                      title: 'Pacientes',
                      value: '${snapshot.data?.length ?? 0}',
                      icon: Icons.people,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatientListPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                DashboardCard(
                  title: 'Alimentos',
                  value: '${FoodRepository().search('').length}',
                  icon: Icons.eco_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FoodDatabasePage(),
                      ),
                    );
                  },
                ),
                StreamBuilder<List<MealPlanModel>>(
                  stream: MealPlanRepository().watchAll(),
                  builder: (context, snapshot) {
                    return DashboardCard(
                      title: 'Planos',
                      value: '${snapshot.data?.length ?? 0}',
                      icon: Icons.restaurant_menu,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MealPlanPatientSelectPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                StreamBuilder<List<HistoryEventModel>>(
                  stream: HistoryRepository().watchAll(),
                  builder: (context, snapshot) {
                    return DashboardCard(
                      title: 'Historico',
                      value: '${snapshot.data?.length ?? 0}',
                      icon: Icons.history,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Atalhos rapidos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ShortcutActions(
              onNewPatient: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientFormPage()),
                );
              },
              onMealPlan: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MealPlanPatientSelectPage(),
                  ),
                );
              },
              onFoods: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodDatabasePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncCloud() async {
    if (!_syncService.canSync) {
      _showMessage('Entre com Supabase configurado para sincronizar.');
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final result = await _syncService.syncAll();
      _showMessage('Sincronizacao concluida (${result.total} registros).');
    } catch (error) {
      _showMessage('Falha ao sincronizar: $error');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ShortcutActions extends StatelessWidget {
  final VoidCallback onNewPatient;
  final VoidCallback onMealPlan;
  final VoidCallback onFoods;

  const _ShortcutActions({
    required this.onNewPatient,
    required this.onMealPlan,
    required this.onFoods,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ElevatedButton.icon(
        onPressed: onNewPatient,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar paciente'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: Colors.green,
        ),
      ),
      OutlinedButton.icon(
        onPressed: onMealPlan,
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Montar plano alimentar'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
      OutlinedButton.icon(
        onPressed: onFoods,
        icon: const Icon(Icons.eco_outlined),
        label: const Text('Banco de alimentos'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    ];

    if (Responsive.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final button in buttons) ...[
            button,
            if (button != buttons.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (final button in buttons) ...[
          Expanded(child: button),
          if (button != buttons.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 32),
            if (!Responsive.isMobile(context)) const Spacer(),
            if (Responsive.isMobile(context)) const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
