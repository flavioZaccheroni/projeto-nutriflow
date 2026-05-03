import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/repositories/clinical_repository.dart';

class ClinicalRecordPage extends StatefulWidget {
  const ClinicalRecordPage({super.key, required this.patient});

  final PatientModel patient;

  @override
  State<ClinicalRecordPage> createState() => _ClinicalRecordPageState();
}

class _ClinicalRecordPageState extends State<ClinicalRecordPage> {
  final _repository = ClinicalRepository();
  final _clinicalFormKey = GlobalKey<FormState>();
  final _anthropometryFormKey = GlobalKey<FormState>();
  final _labsFormKey = GlobalKey<FormState>();
  final _nutritionFormKey = GlobalKey<FormState>();
  final _screeningFormKey = GlobalKey<FormState>();

  final _clinical = <String, TextEditingController>{};
  final _anthropometry = <String, TextEditingController>{};
  final _labs = <String, TextEditingController>{};
  final _nutrition = <String, TextEditingController>{};
  final _screening = <String, TextEditingController>{};

  String _formula = 'Mifflin-St Jeor';
  String _protocol = 'NRS-2002';
  String _message = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _createControllers();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      ..._clinical.values,
      ..._anthropometry.values,
      ..._labs.values,
      ..._nutrition.values,
      ..._screening.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Prontuario - ${widget.patient.name}'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.badge_outlined), text: 'Cadastro clinico'),
              Tab(
                icon: Icon(Icons.monitor_weight_outlined),
                text: 'Antropometria',
              ),
              Tab(icon: Icon(Icons.science_outlined), text: 'Exames'),
              Tab(icon: Icon(Icons.calculate_outlined), text: 'Calculo'),
              Tab(
                icon: Icon(Icons.assignment_turned_in_outlined),
                text: 'Triagem',
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_message.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: Colors.green.shade50,
                      child: Text(
                        _message,
                        style: TextStyle(color: Colors.green.shade900),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _clinicalTab(),
                        _anthropometryTab(),
                        _labsTab(),
                        _nutritionTab(),
                        _screeningTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _createControllers() {
    for (final key in [
      'sus_number',
      'insurance',
      'hospital_record',
      'clinical_history',
      'diagnoses',
      'medications',
      'allergies',
      'food_social_history',
      'lifestyle_habits',
      'pep_integration_notes',
    ]) {
      _clinical[key] = TextEditingController();
    }
    for (final key in [
      'weight',
      'height',
      'arm_circumference',
      'calf_circumference',
      'waist_circumference',
      'skinfolds',
      'bioimpedance',
      'body_composition',
      'sarcopenia_risk',
    ]) {
      _anthropometry[key] = TextEditingController();
    }
    for (final key in [
      'albumin',
      'pcr',
      'urea',
      'creatinine',
      'sodium',
      'potassium',
      'phosphorus',
      'hemoglobin',
      'glucose',
      'hba1c',
      'interpretation',
    ]) {
      _labs[key] = TextEditingController();
    }
    for (final key in [
      'energy_need',
      'stress_factor',
      'protein_gkg',
      'carbs_g',
      'lipids_g',
      'meal_distribution',
      'micronutrients',
      'clinical_adjustments',
    ]) {
      _nutrition[key] = TextEditingController();
    }
    for (final key in ['score', 'alerts']) {
      _screening[key] = TextEditingController();
    }
  }

  Future<void> _load() async {
    final clinical = await _repository.getClinicalRecord(widget.patient.id);
    final anthropometry = await _repository.getLatest(
      'anthropometric_assessments',
      widget.patient.id,
    );
    final labs = await _repository.getLatest('lab_results', widget.patient.id);
    final nutrition = await _repository.getLatest(
      'nutrition_calculations',
      widget.patient.id,
    );
    final screening = await _repository.getLatest(
      'screening_results',
      widget.patient.id,
    );

    _fill(_clinical, clinical);
    _fill(_anthropometry, anthropometry);
    _fill(_labs, labs);
    _fill(_nutrition, nutrition);
    _fill(_screening, screening);
    _formula = (nutrition['formula'] as String?) ?? _formula;
    _protocol = (screening['protocol'] as String?) ?? _protocol;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _fill(
    Map<String, TextEditingController> controllers,
    Map<String, Object?> values,
  ) {
    for (final entry in controllers.entries) {
      final value = values[entry.key];
      if (value != null) {
        entry.value.text = value.toString();
      }
    }
  }

  Widget _page(Widget child) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: ResponsiveCenter(
        maxWidth: Responsive.contentMaxWidth(context),
        child: child,
      ),
    );
  }

  Widget _clinicalTab() {
    return _page(
      Form(
        key: _clinicalFormKey,
        child: _SectionCard(
          title: 'Cadastro clinico completo',
          subtitle: 'Identificacao, historico, diagnosticos, PEP e habitos.',
          children: [
            _FieldsGrid(
              children: [
                _text(_clinical, 'sus_number', 'Cartao SUS'),
                _text(_clinical, 'insurance', 'Convenio'),
                _text(_clinical, 'hospital_record', 'Prontuario hospitalar'),
                _text(
                  _clinical,
                  'clinical_history',
                  'Historico clinico detalhado',
                  maxLines: 4,
                ),
                _text(_clinical, 'diagnoses', 'Diagnosticos CID-10 / CID-11'),
                _text(_clinical, 'medications', 'Medicamentos em uso'),
                _text(_clinical, 'allergies', 'Alergias e intolerancias'),
                _text(
                  _clinical,
                  'food_social_history',
                  'Historico alimentar e social',
                  maxLines: 4,
                ),
                _text(
                  _clinical,
                  'lifestyle_habits',
                  'Sono, atividade fisica, alcool e tabaco',
                  maxLines: 4,
                ),
                _text(
                  _clinical,
                  'pep_integration_notes',
                  'Notas de integracao com PEP',
                  maxLines: 4,
                ),
              ],
            ),
            _saveButton('Salvar cadastro clinico', _saveClinical),
          ],
        ),
      ),
    );
  }

  Widget _anthropometryTab() {
    final bmi = _calculatedBmi();
    return _page(
      Form(
        key: _anthropometryFormKey,
        child: _SectionCard(
          title: 'Avaliacao antropometrica avancada',
          subtitle: bmi == null
              ? 'Circunferencias, dobras, bioimpedancia e composicao corporal.'
              : 'IMC calculado: ${bmi.toStringAsFixed(1)} kg/m2',
          children: [
            _FieldsGrid(
              children: [
                _number(_anthropometry, 'weight', 'Peso (kg)'),
                _number(_anthropometry, 'height', 'Altura (cm)'),
                _number(_anthropometry, 'arm_circumference', 'CB - braco (cm)'),
                _number(
                  _anthropometry,
                  'calf_circumference',
                  'CP - panturrilha (cm)',
                ),
                _number(
                  _anthropometry,
                  'waist_circumference',
                  'CC - cintura (cm)',
                ),
                _text(_anthropometry, 'skinfolds', 'Dobras cutaneas'),
                _text(_anthropometry, 'bioimpedance', 'Bioimpedancia'),
                _text(
                  _anthropometry,
                  'body_composition',
                  'Composicao corporal',
                ),
                _text(_anthropometry, 'sarcopenia_risk', 'Risco de sarcopenia'),
              ],
            ),
            _saveButton('Registrar antropometria', _saveAnthropometry),
          ],
        ),
      ),
    );
  }

  Widget _labsTab() {
    return _page(
      Form(
        key: _labsFormKey,
        child: _SectionCard(
          title: 'Exames laboratoriais',
          subtitle: 'Registre exames e gere alertas clinicos automaticos.',
          children: [
            _FieldsGrid(
              children: [
                _number(_labs, 'albumin', 'Albumina'),
                _number(_labs, 'pcr', 'PCR'),
                _number(_labs, 'urea', 'Ureia'),
                _number(_labs, 'creatinine', 'Creatinina'),
                _number(_labs, 'sodium', 'Sodio (Na)'),
                _number(_labs, 'potassium', 'Potassio (K)'),
                _number(_labs, 'phosphorus', 'Fosforo (P)'),
                _number(_labs, 'hemoglobin', 'Hemoglobina'),
                _number(_labs, 'glucose', 'Glicemia'),
                _number(_labs, 'hba1c', 'HbA1c'),
                _text(
                  _labs,
                  'interpretation',
                  'Interpretacao clinica',
                  maxLines: 4,
                ),
              ],
            ),
            _saveButton('Salvar exames', _saveLabs),
          ],
        ),
      ),
    );
  }

  Widget _nutritionTab() {
    return _page(
      Form(
        key: _nutritionFormKey,
        child: _SectionCard(
          title: 'Calculo nutricional completo',
          subtitle: 'Energia, estresse metabolico, macros e ajustes clinicos.',
          children: [
            _FieldsGrid(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _formula,
                  decoration: const InputDecoration(labelText: 'Formula'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Mifflin-St Jeor',
                      child: Text('Mifflin-St Jeor'),
                    ),
                    DropdownMenuItem(
                      value: 'Harris-Benedict',
                      child: Text('Harris-Benedict'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _formula = value ?? _formula;
                  }),
                ),
                _number(
                  _nutrition,
                  'energy_need',
                  'Necessidade energetica (kcal)',
                ),
                _number(_nutrition, 'stress_factor', 'Fator de estresse'),
                _number(_nutrition, 'protein_gkg', 'Proteina (g/kg)'),
                _number(_nutrition, 'carbs_g', 'Carboidratos (g)'),
                _number(_nutrition, 'lipids_g', 'Lipidios (g)'),
                _text(
                  _nutrition,
                  'meal_distribution',
                  'Distribuicao por refeicao',
                  maxLines: 4,
                ),
                _text(
                  _nutrition,
                  'micronutrients',
                  'Vitaminas e minerais',
                  maxLines: 4,
                ),
                _text(
                  _nutrition,
                  'clinical_adjustments',
                  'Ajustes para patologias',
                  maxLines: 4,
                ),
              ],
            ),
            _saveButton('Calcular e salvar', _saveNutrition),
          ],
        ),
      ),
    );
  }

  Widget _screeningTab() {
    return _page(
      Form(
        key: _screeningFormKey,
        child: _SectionCard(
          title: 'Protocolos clinicos e triagem',
          subtitle: 'NRS-2002, MUST, SGA e GLIM com prioridade automatica.',
          children: [
            _FieldsGrid(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _protocol,
                  decoration: const InputDecoration(labelText: 'Protocolo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'NRS-2002',
                      child: Text('NRS-2002'),
                    ),
                    DropdownMenuItem(value: 'MUST', child: Text('MUST')),
                    DropdownMenuItem(value: 'SGA', child: Text('SGA')),
                    DropdownMenuItem(value: 'GLIM', child: Text('GLIM')),
                  ],
                  onChanged: (value) => setState(() {
                    _protocol = value ?? _protocol;
                  }),
                ),
                _number(_screening, 'score', 'Pontuacao'),
                _text(_screening, 'alerts', 'Alertas adicionais', maxLines: 4),
              ],
            ),
            _saveButton('Salvar triagem', _saveScreening),
          ],
        ),
      ),
    );
  }

  Widget _text(
    Map<String, TextEditingController> controllers,
    String key,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controllers[key],
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _number(
    Map<String, TextEditingController> controllers,
    String key,
    String label,
  ) {
    return TextFormField(
      controller: controllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _saveButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_outlined),
        label: Text(label),
      ),
    );
  }

  Map<String, Object?> _data(Map<String, TextEditingController> controllers) {
    return {
      for (final entry in controllers.entries)
        entry.key: _value(entry.value.text),
    };
  }

  Object? _value(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return double.tryParse(trimmed.replaceAll(',', '.')) ?? trimmed;
  }

  double? _calculatedBmi() {
    final weight =
        double.tryParse(_anthropometry['weight']!.text.replaceAll(',', '.')) ??
        widget.patient.weight;
    final height =
        double.tryParse(_anthropometry['height']!.text.replaceAll(',', '.')) ??
        widget.patient.height;
    if (height <= 0) {
      return null;
    }
    return weight / ((height / 100) * (height / 100));
  }

  Future<void> _saveClinical() async {
    await _repository.saveClinicalRecord(
      patientId: widget.patient.id,
      data: _data(_clinical),
    );
    _showMessage('Cadastro clinico salvo com sucesso.');
  }

  Future<void> _saveAnthropometry() async {
    await _repository.saveAnthropometry(
      patient: widget.patient,
      data: _data(_anthropometry),
    );
    _showMessage('Avaliacao antropometrica registrada.');
  }

  Future<void> _saveLabs() async {
    await _repository.saveLabs(
      patientId: widget.patient.id,
      data: _data(_labs),
    );
    final latest = await _repository.getLatest(
      'lab_results',
      widget.patient.id,
    );
    final alerts = latest['alerts'] as String? ?? '';
    _showMessage(
      alerts.isEmpty ? 'Exames salvos sem alertas.' : 'Alertas: $alerts.',
    );
  }

  Future<void> _saveNutrition() async {
    await _repository.saveNutritionCalculation(
      patient: widget.patient,
      data: {..._data(_nutrition), 'formula': _formula},
    );
    _showMessage('Calculo nutricional salvo.');
  }

  Future<void> _saveScreening() async {
    await _repository.saveScreening(
      patientId: widget.patient.id,
      data: {..._data(_screening), 'protocol': _protocol},
    );
    final latest = await _repository.getLatest(
      'screening_results',
      widget.patient.id,
    );
    _showMessage(
      'Triagem: ${latest['classification']} | prioridade ${latest['priority']}.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _message = message);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldsGrid extends StatelessWidget {
  const _FieldsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.isDesktop(context) ? 2 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
