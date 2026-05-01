import 'package:flutter/material.dart';

import '../../../../data/models/patient_model.dart';
import '../../../../data/repositories/patient_repository.dart';
import 'patient_form_page.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final _repository = PatientRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      body: StreamBuilder<List<PatientModel>>(
        stream: _repository.watchAll(),
        builder: (context, snapshot) {
          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return const _EmptyPatientsState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final patient = patients[index];

              return Dismissible(
                key: ValueKey(patient.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _repository.delete(patient.id),
                child: Card(
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
                      '${patient.goal}\n'
                      '${patient.age} anos | ${patient.weight.toStringAsFixed(1)} kg | '
                      'IMC ${patient.imc.toStringAsFixed(1)}'
                      '${patient.observations.isEmpty ? '' : '\nObs: ${patient.observations}'}',
                    ),
                    isThreeLine: patient.observations.isNotEmpty,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openForm(patient),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm([PatientModel? patient]) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientFormPage(patient: patient)),
    );
  }
}

class _EmptyPatientsState extends StatelessWidget {
  const _EmptyPatientsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 72, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nenhum paciente cadastrado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque em adicionar para criar o primeiro registro local.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
