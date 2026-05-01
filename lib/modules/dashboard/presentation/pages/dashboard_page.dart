import 'package:flutter/material.dart';

import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/models/history_event_model.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../data/repositories/meal_plan_repository.dart';
import '../../../../data/repositories/patient_repository.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../meal_plans/presentation/pages/meal_plan_patient_select_page.dart';
import '../../../patients/presentation/pages/patient_form_page.dart';
import '../../../patients/presentation/pages/patient_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
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
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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
                const DashboardCard(
                  title: 'Consultas',
                  value: '18',
                  icon: Icons.calendar_today,
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientFormPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar paciente'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MealPlanPatientSelectPage(),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Montar plano alimentar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
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
            const Spacer(),
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
