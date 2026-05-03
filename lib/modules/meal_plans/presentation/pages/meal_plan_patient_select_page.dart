import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/repositories/patient_repository.dart';
import 'meal_plan_editor_page.dart';

class MealPlanPatientSelectPage extends StatelessWidget {
  const MealPlanPatientSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = PatientRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar paciente')),
      body: StreamBuilder<List<PatientModel>>(
        stream: repository.watchAll(),
        builder: (context, snapshot) {
          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return const _NoPatientsState();
          }

          return ResponsiveCenter(
            maxWidth: Responsive.contentMaxWidth(context),
            child: GridView.builder(
              padding: Responsive.pagePadding(context),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.listColumns(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent:
                    patients.any((patient) => patient.observations.isNotEmpty)
                    ? 120
                    : 96,
              ),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade800,
                      child: Text(patient.name.characters.first.toUpperCase()),
                    ),
                    title: Text(patient.name),
                    subtitle: Text(
                      patient.observations.isEmpty
                          ? patient.goal
                          : '${patient.goal}\nObs: ${patient.observations}',
                    ),
                    isThreeLine: patient.observations.isNotEmpty,
                    trailing: const Icon(Icons.restaurant_menu),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealPlanEditorPage(patient: patient),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NoPatientsState extends StatelessWidget {
  const _NoPatientsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Cadastre um paciente antes de montar um plano alimentar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
