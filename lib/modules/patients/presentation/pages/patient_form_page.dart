import 'package:flutter/material.dart';

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final goalController = TextEditingController();

  void savePatient() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente cadastrado com sucesso!'),
        ),
      );

      nameController.clear();
      ageController.clear();
      weightController.clear();
      heightController.clear();
      goalController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Paciente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildField(nameController, 'Nome'),
              buildField(ageController, 'Idade', number: true),
              buildField(weightController, 'Peso (kg)', number: true),
              buildField(heightController, 'Altura (m)', number: true),
              buildField(goalController, 'Objetivo'),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: savePatient,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
      TextEditingController controller,
      String label, {
        bool number = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType:
        number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo obrigatório';
          }
          return null;
        },
      ),
    );
  }
}