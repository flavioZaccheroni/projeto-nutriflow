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
  final _prescription = <String, TextEditingController>{};
  final _evolution = <String, TextEditingController>{};
  final _alerts = <String, TextEditingController>{};
  final _reports = <String, TextEditingController>{};
  final _patientExperience = <String, TextEditingController>{};
  final _security = <String, TextEditingController>{};
  final _integrations = <String, TextEditingController>{};

  String _formula = 'Mifflin-St Jeor';
  String _protocol = 'NRS-2002';
  String _evolutionModel = 'SOAP';
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
      ..._prescription.values,
      ..._evolution.values,
      ..._alerts.values,
      ..._reports.values,
      ..._patientExperience.values,
      ..._security.values,
      ..._integrations.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 12,
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
              Tab(
                icon: Icon(Icons.restaurant_menu_outlined),
                text: 'Prescricao',
              ),
              Tab(icon: Icon(Icons.timeline_outlined), text: 'Evolucao'),
              Tab(icon: Icon(Icons.warning_amber_outlined), text: 'Alertas'),
              Tab(icon: Icon(Icons.query_stats_outlined), text: 'Indicadores'),
              Tab(icon: Icon(Icons.phone_iphone_outlined), text: 'Paciente'),
              Tab(icon: Icon(Icons.verified_user_outlined), text: 'Seguranca'),
              Tab(icon: Icon(Icons.sync_alt_outlined), text: 'Integracoes'),
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
                        _prescriptionTab(),
                        _evolutionTab(),
                        _alertsTab(),
                        _reportsTab(),
                        _patientExperienceTab(),
                        _securityTab(),
                        _integrationsTab(),
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
    for (final key in [
      'oral_plan',
      'oral_menu_mode',
      'enteral_formula',
      'enteral_volume',
      'enteral_hours',
      'enteral_density',
      'enteral_tolerance',
      'parenteral_macros',
      'parenteral_osmolarity',
      'parenteral_compatibility',
      'parenteral_electrolytes',
      'delivery_notes',
    ]) {
      _prescription[key] = TextEditingController();
    }
    for (final key in [
      'subjective',
      'objective',
      'assessment',
      'plan',
      'comparison',
      'incidents',
      'multiprofessional_notes',
    ]) {
      _evolution[key] = TextEditingController();
    }
    for (final key in [
      'drug_nutrient_interactions',
      'refeeding_risk',
      'renal_hepatic_restrictions',
      'electrolyte_alerts',
      'protein_alert',
    ]) {
      _alerts[key] = TextEditingController();
    }
    for (final key in [
      'patient_evolution',
      'plan_adherence',
      'clinical_results',
      'quality_indicators',
      'malnutrition_rate',
      'intervention_time',
      'audit_notes',
    ]) {
      _reports[key] = TextEditingController();
    }
    for (final key in [
      'digital_plan_status',
      'substitutions',
      'reminders',
      'chat_notes',
      'web_access_notes',
    ]) {
      _patientExperience[key] = TextEditingController();
    }
    for (final key in [
      'lgpd_consent',
      'digital_signature',
      'access_profile',
      'backup_status',
      'audit_log',
    ]) {
      _security[key] = TextEditingController();
    }
    for (final key in [
      'hospital_pep',
      'laboratories',
      'bioimpedance_devices',
      'insurance_sus',
      'finance_schedule',
      'sync_status',
    ]) {
      _integrations[key] = TextEditingController();
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
    final prescription = await _repository.getLatest(
      'diet_prescriptions',
      widget.patient.id,
    );
    final evolution = await _repository.getLatest(
      'nutritional_evolutions',
      widget.patient.id,
    );
    final alerts = await _repository.getLatest(
      'intelligent_alerts',
      widget.patient.id,
    );
    final reports = await _repository.getLatest(
      'clinical_reports',
      widget.patient.id,
    );
    final patientExperience = await _repository.getLatest(
      'patient_experience_records',
      widget.patient.id,
    );
    final security = await _repository.getLatest(
      'security_records',
      widget.patient.id,
    );
    final integrations = await _repository.getLatest(
      'integration_records',
      widget.patient.id,
    );

    _fill(_clinical, clinical);
    _fill(_anthropometry, anthropometry);
    _fill(_labs, labs);
    _fill(_nutrition, nutrition);
    _fill(_screening, screening);
    _fill(_prescription, prescription);
    _fill(_evolution, evolution);
    _fill(_alerts, alerts);
    _fill(_reports, reports);
    _fill(_patientExperience, patientExperience);
    _fill(_security, security);
    _fill(_integrations, integrations);
    _formula = (nutrition['formula'] as String?) ?? _formula;
    _protocol = (screening['protocol'] as String?) ?? _protocol;
    _evolutionModel = (evolution['model'] as String?) ?? _evolutionModel;

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

  Widget _prescriptionTab() {
    return _page(
      _SectionCard(
        title: 'Prescricao dietetica',
        subtitle:
            'Dieta oral, enteral e parenteral com calculos clinicos basicos.',
        children: [
          _FieldsGrid(
            children: [
              _text(
                _prescription,
                'oral_plan',
                'Dieta oral e cardapio',
                maxLines: 4,
              ),
              _text(
                _prescription,
                'oral_menu_mode',
                'Montagem manual/automatica',
              ),
              _text(
                _prescription,
                'enteral_formula',
                'Formula enteral comercial',
              ),
              _number(
                _prescription,
                'enteral_volume',
                'Volume enteral (ml/dia)',
              ),
              _number(_prescription, 'enteral_hours', 'Tempo de infusao (h)'),
              _number(_prescription, 'enteral_density', 'Densidade (kcal/ml)'),
              _text(
                _prescription,
                'enteral_tolerance',
                'Evolucao de tolerancia enteral',
                maxLines: 4,
              ),
              _text(
                _prescription,
                'parenteral_macros',
                'Parenteral: macros detalhados',
                maxLines: 4,
              ),
              _number(
                _prescription,
                'parenteral_osmolarity',
                'Osmolaridade parenteral',
              ),
              _text(
                _prescription,
                'parenteral_compatibility',
                'Compatibilidade',
                maxLines: 4,
              ),
              _text(
                _prescription,
                'parenteral_electrolytes',
                'Eletrolitos ajustados',
                maxLines: 4,
              ),
              _text(
                _prescription,
                'delivery_notes',
                'Envio ao paciente: PDF/WhatsApp',
                maxLines: 4,
              ),
            ],
          ),
          _saveButton('Salvar prescricao', _savePrescription),
        ],
      ),
    );
  }

  Widget _evolutionTab() {
    return _page(
      _SectionCard(
        title: 'Evolucao nutricional e prontuario',
        subtitle: 'Registro diario, comparacoes, intercorrencias e auditoria.',
        children: [
          _FieldsGrid(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _evolutionModel,
                decoration: const InputDecoration(labelText: 'Modelo'),
                items: const [
                  DropdownMenuItem(value: 'SOAP', child: Text('SOAP')),
                  DropdownMenuItem(value: 'Livre', child: Text('Livre')),
                ],
                onChanged: (value) => setState(() {
                  _evolutionModel = value ?? _evolutionModel;
                }),
              ),
              _text(_evolution, 'subjective', 'Subjetivo', maxLines: 4),
              _text(_evolution, 'objective', 'Objetivo', maxLines: 4),
              _text(_evolution, 'assessment', 'Avaliacao', maxLines: 4),
              _text(_evolution, 'plan', 'Plano', maxLines: 4),
              _text(
                _evolution,
                'comparison',
                'Comparacao: peso, exames e ingestao',
                maxLines: 4,
              ),
              _text(_evolution, 'incidents', 'Intercorrencias', maxLines: 4),
              _text(
                _evolution,
                'multiprofessional_notes',
                'Anotacoes multiprofissionais',
                maxLines: 4,
              ),
            ],
          ),
          _saveButton('Salvar evolucao', _saveEvolution),
        ],
      ),
    );
  }

  Widget _alertsTab() {
    return _page(
      _SectionCard(
        title: 'Alertas clinicos inteligentes',
        subtitle:
            'Interacoes, realimentacao, restricoes renal/hepatica e proteina.',
        children: [
          _FieldsGrid(
            children: [
              _text(
                _alerts,
                'drug_nutrient_interactions',
                'Interacao farmaco-nutriente',
                maxLines: 4,
              ),
              _text(_alerts, 'refeeding_risk', 'Risco de realimentacao'),
              _text(
                _alerts,
                'renal_hepatic_restrictions',
                'Restricoes renal/hepatica',
                maxLines: 4,
              ),
              _text(
                _alerts,
                'electrolyte_alerts',
                'Alertas de eletrolitos criticos',
                maxLines: 4,
              ),
              _text(
                _alerts,
                'protein_alert',
                'Ingestao proteica inadequada',
                maxLines: 4,
              ),
            ],
          ),
          _saveButton('Gerar e salvar alertas', _saveAlerts),
        ],
      ),
    );
  }

  Widget _reportsTab() {
    return _page(
      _SectionCard(
        title: 'Relatorios e indicadores',
        subtitle: 'Consultorio, hospital, qualidade e auditorias.',
        children: [
          _FieldsGrid(
            children: [
              _text(
                _reports,
                'patient_evolution',
                'Evolucao do paciente',
                maxLines: 4,
              ),
              _text(_reports, 'plan_adherence', 'Adesao ao plano'),
              _text(
                _reports,
                'clinical_results',
                'Resultados clinicos',
                maxLines: 4,
              ),
              _text(
                _reports,
                'quality_indicators',
                'Indicadores de qualidade',
                maxLines: 4,
              ),
              _text(_reports, 'malnutrition_rate', 'Taxa de desnutricao'),
              _text(
                _reports,
                'intervention_time',
                'Tempo de intervencao nutricional',
              ),
              _text(_reports, 'audit_notes', 'Auditorias', maxLines: 4),
            ],
          ),
          _saveButton('Salvar indicadores', _saveReport),
        ],
      ),
    );
  }

  Widget _patientExperienceTab() {
    return _page(
      _SectionCard(
        title: 'Experiencia do paciente',
        subtitle: 'Plano digital, substituicoes, lembretes e chat.',
        children: [
          _FieldsGrid(
            children: [
              _text(
                _patientExperience,
                'digital_plan_status',
                'Status do plano alimentar digital',
              ),
              _text(
                _patientExperience,
                'substitutions',
                'Lista de substituicoes',
                maxLines: 4,
              ),
              _text(_patientExperience, 'reminders', 'Lembretes', maxLines: 4),
              _text(
                _patientExperience,
                'chat_notes',
                'Chat com nutricionista',
                maxLines: 4,
              ),
              _text(
                _patientExperience,
                'web_access_notes',
                'App ou acesso web',
                maxLines: 4,
              ),
            ],
          ),
          _saveButton('Salvar experiencia', _savePatientExperience),
        ],
      ),
    );
  }

  Widget _securityTab() {
    return _page(
      _SectionCard(
        title: 'Seguranca e legislacao',
        subtitle: 'LGPD, assinatura digital, perfis, backup e auditoria.',
        children: [
          _FieldsGrid(
            children: [
              _text(_security, 'lgpd_consent', 'Consentimento LGPD'),
              _text(_security, 'digital_signature', 'Assinatura digital'),
              _text(_security, 'access_profile', 'Perfil de acesso'),
              _text(_security, 'backup_status', 'Backup automatico'),
              _text(
                _security,
                'audit_log',
                'Registro de auditoria',
                maxLines: 4,
              ),
            ],
          ),
          _saveButton('Salvar seguranca', _saveSecurity),
        ],
      ),
    );
  }

  Widget _integrationsTab() {
    return _page(
      _SectionCard(
        title: 'Integracoes',
        subtitle: 'PEP, laboratorios, equipamentos, convenios, SUS e agenda.',
        children: [
          _FieldsGrid(
            children: [
              _text(
                _integrations,
                'hospital_pep',
                'Prontuario eletronico hospitalar',
              ),
              _text(_integrations, 'laboratories', 'Laboratorios'),
              _text(
                _integrations,
                'bioimpedance_devices',
                'Equipamentos de bioimpedancia',
              ),
              _text(_integrations, 'insurance_sus', 'Convenios / SUS'),
              _text(_integrations, 'finance_schedule', 'Financeiro e agenda'),
              _text(
                _integrations,
                'sync_status',
                'Status da integracao',
                maxLines: 4,
              ),
            ],
          ),
          _saveButton('Salvar integracoes', _saveIntegrations),
        ],
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

  Future<void> _savePrescription() async {
    await _repository.saveDietPrescription(
      patientId: widget.patient.id,
      data: _data(_prescription),
    );
    final latest = await _repository.getLatest(
      'diet_prescriptions',
      widget.patient.id,
    );
    final speed = latest['enteral_speed'];
    _showMessage(
      speed == null
          ? 'Prescricao dietetica salva.'
          : 'Prescricao salva. Velocidade enteral: ${_formatNumber(speed)} ml/h.',
    );
  }

  Future<void> _saveEvolution() async {
    await _repository.saveEvolution(
      patientId: widget.patient.id,
      data: {..._data(_evolution), 'model': _evolutionModel},
    );
    _showMessage('Evolucao nutricional registrada.');
  }

  Future<void> _saveAlerts() async {
    final generated = await _repository.saveIntelligentAlerts(
      patient: widget.patient,
      data: _data(_alerts),
    );
    _showMessage(
      generated.isEmpty
          ? 'Alertas revisados sem alerta automatico.'
          : 'Alertas gerados: $generated.',
    );
  }

  Future<void> _saveReport() async {
    await _repository.saveClinicalReport(
      patientId: widget.patient.id,
      data: _data(_reports),
    );
    _showMessage('Relatorio e indicadores salvos.');
  }

  Future<void> _savePatientExperience() async {
    await _repository.savePatientExperience(
      patientId: widget.patient.id,
      data: _data(_patientExperience),
    );
    _showMessage('Experiencia do paciente salva.');
  }

  Future<void> _saveSecurity() async {
    await _repository.saveSecurityRecord(
      patientId: widget.patient.id,
      data: _data(_security),
    );
    _showMessage('Seguranca, LGPD e auditoria salvos.');
  }

  Future<void> _saveIntegrations() async {
    await _repository.saveIntegrationRecord(
      patientId: widget.patient.id,
      data: _data(_integrations),
    );
    _showMessage('Integracoes registradas.');
  }

  String _formatNumber(Object value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return number.toStringAsFixed(1);
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
