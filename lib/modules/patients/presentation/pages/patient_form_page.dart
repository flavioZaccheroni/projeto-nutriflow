import 'package:flutter/material.dart';

import '../../../../data/models/patient_model.dart';
import '../../../../data/repositories/patient_repository.dart';

class PatientFormPage extends StatefulWidget {
  final PatientModel? patient;

  const PatientFormPage({super.key, this.patient});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PatientRepository();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _goalController;
  late final TextEditingController _observationsController;
  late final TextEditingController _nextVisitController;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    _nameController = TextEditingController(text: patient?.name ?? '');
    _ageController = TextEditingController(text: patient?.age.toString() ?? '');
    _weightController = TextEditingController(
      text: patient?.weight.toStringAsFixed(1) ?? '',
    );
    _heightController = TextEditingController(
      text: patient?.height.toStringAsFixed(0) ?? '',
    );
    _goalController = TextEditingController(text: patient?.goal ?? '');
    _observationsController = TextEditingController(
      text: patient?.observations ?? '',
    );
    _nextVisitController = TextEditingController(
      text: patient?.nextVisit ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    _observationsController.dispose();
    _nextVisitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar paciente' : 'Novo paciente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Idade',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _positiveInt,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: _positiveDouble,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Altura (cm)',
                prefixIcon: Icon(Icons.height),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _positiveDouble,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Objetivo',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observacoes',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nextVisitController,
              decoration: const InputDecoration(
                labelText: 'Proxima consulta',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              textInputAction: TextInputAction.done,
              validator: _required,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar paciente'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final existing = widget.patient;
    final patient = PatientModel(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      weight: _parseDouble(_weightController.text),
      height: _parseDouble(_heightController.text),
      goal: _goalController.text.trim(),
      observations: _observationsController.text.trim(),
      nextVisit: _nextVisitController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await _repository.save(patient);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Preencha este campo';
    }
    return null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Informe um numero valido';
    }
    return null;
  }

  String? _positiveDouble(String? value) {
    final parsed = _tryParseDouble(value);
    if (parsed == null || parsed <= 0) {
      return 'Informe um numero valido';
    }
    return null;
  }

  double _parseDouble(String value) {
    return _tryParseDouble(value)!;
  }

  double? _tryParseDouble(String? value) {
    return double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  }
}
