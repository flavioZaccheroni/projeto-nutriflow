import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/repositories/meal_plan_repository.dart';
import '../../../../data/services/diet_pdf_report_service.dart';

class MealPlanEditorPage extends StatefulWidget {
  final PatientModel patient;

  const MealPlanEditorPage({super.key, required this.patient});

  @override
  State<MealPlanEditorPage> createState() => _MealPlanEditorPageState();
}

class _MealPlanEditorPageState extends State<MealPlanEditorPage> {
  final _repository = MealPlanRepository();
  final _pdfReportService = DietPdfReportService();
  final List<_MealDraft> _meals = [];
  String _planId = '';
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final plan = await _repository.findByPatientId(widget.patient.id);
    _planId = plan?.id ?? '';

    if (plan == null || plan.meals.isEmpty) {
      _meals.addAll([
        _MealDraft(name: 'Cafe da manha', time: '07:00'),
        _MealDraft(name: 'Almoco', time: '12:00'),
        _MealDraft(name: 'Jantar', time: '19:00'),
      ]);
    } else {
      _meals.addAll(plan.meals.map(_MealDraft.fromModel));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (final meal in _meals) {
      meal.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Plano alimentar'),
        actions: [
          IconButton(
            tooltip: 'Gerar PDF',
            onPressed: _isSaving || _isGeneratingPdf ? null : _generatePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Salvar plano',
            onPressed: _isSaving ? null : _savePlan,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCenter(
              maxWidth: Responsive.contentMaxWidth(context),
              child: ListView(
                padding: Responsive.pagePadding(context),
                children: [
                  _PatientHeader(patient: widget.patient),
                  const SizedBox(height: 16),
                  for (final meal in _meals) ...[
                    _MealEditorCard(
                      meal: meal,
                      onRemove: _meals.length == 1
                          ? null
                          : () => _removeMeal(meal),
                      onAddFood: () => _addFood(meal),
                      onRemoveFood: (food) => _removeFood(meal, food),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _addMeal,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar refeicao'),
                  ),
                  const SizedBox(height: 88),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: _BottomActions(
            isSaving: _isSaving,
            isGeneratingPdf: _isGeneratingPdf,
            onSave: _savePlan,
            onGeneratePdf: _generatePdf,
          ),
        ),
      ),
    );
  }

  void _addMeal() {
    setState(() {
      _meals.add(_MealDraft(name: 'Nova refeicao', time: ''));
    });
  }

  void _removeMeal(_MealDraft meal) {
    setState(() {
      _meals.remove(meal);
      meal.dispose();
    });
  }

  void _addFood(_MealDraft meal) {
    setState(() {
      meal.foods.add(_FoodDraft());
    });
  }

  void _removeFood(_MealDraft meal, _FoodDraft food) {
    setState(() {
      meal.foods.remove(food);
      food.dispose();
    });
  }

  Future<void> _savePlan() async {
    final plan = await _persistPlan();
    if (plan == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plano alimentar salvo.')));
  }

  Future<void> _generatePdf() async {
    final plan = await _persistPlan();
    if (plan == null) {
      return;
    }

    setState(() => _isGeneratingPdf = true);

    final file = await _pdfReportService.generate(
      patient: widget.patient,
      plan: plan,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isGeneratingPdf = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF gerado: ${file.path}'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<MealPlanModel?> _persistPlan() async {
    final invalidMeal = _meals.any(
      (meal) =>
          meal.nameController.text.trim().isEmpty ||
          meal.timeController.text.trim().isEmpty ||
          meal.foods.isEmpty ||
          meal.foods.any(
            (food) =>
                food.nameController.text.trim().isEmpty ||
                food.quantityController.text.trim().isEmpty,
          ),
    );

    if (invalidMeal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha horario, refeicao, alimentos e quantidades.'),
        ),
      );
      return null;
    }

    setState(() => _isSaving = true);

    final plan = MealPlanModel(
      id: _planId,
      patientId: widget.patient.id,
      meals: _meals.map((meal) => meal.toModel()).toList(),
      updatedAt: DateTime.now(),
    );

    final savedPlan = await _repository.save(plan);
    _planId = savedPlan.id;

    if (!mounted) {
      return savedPlan;
    }

    setState(() => _isSaving = false);
    return savedPlan;
  }
}

class _BottomActions extends StatelessWidget {
  final bool isSaving;
  final bool isGeneratingPdf;
  final VoidCallback onSave;
  final VoidCallback onGeneratePdf;

  const _BottomActions({
    required this.isSaving,
    required this.isGeneratingPdf,
    required this.onSave,
    required this.onGeneratePdf,
  });

  @override
  Widget build(BuildContext context) {
    final saveButton = ElevatedButton.icon(
      onPressed: isSaving ? null : onSave,
      icon: const Icon(Icons.save_outlined),
      label: Text(isSaving ? 'Salvando...' : 'Salvar plano alimentar'),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(240, 48),
        backgroundColor: Colors.green,
      ),
    );
    final pdfButton = OutlinedButton.icon(
      onPressed: isSaving || isGeneratingPdf ? null : onGeneratePdf,
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: Text(
        isGeneratingPdf ? 'Gerando PDF...' : 'Gerar PDF para paciente',
      ),
      style: OutlinedButton.styleFrom(fixedSize: const Size(260, 48)),
    );

    if (Responsive.isMobile(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [saveButton, const SizedBox(height: 10), pdfButton],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [saveButton, const SizedBox(width: 12), pdfButton],
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  final PatientModel patient;

  const _PatientHeader({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            foregroundColor: Colors.green.shade800,
            child: Text(patient.name.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  patient.goal,
                  style: const TextStyle(color: Colors.black54),
                ),
                if (patient.observations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    patient.observations,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealEditorCard extends StatelessWidget {
  final _MealDraft meal;
  final VoidCallback? onRemove;
  final VoidCallback onAddFood;
  final ValueChanged<_FoodDraft> onRemoveFood;

  const _MealEditorCard({
    required this.meal,
    required this.onRemove,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _EditorRow(
            children: [
              _ResponsiveExpanded(
                flex: 3,
                child: TextField(
                  controller: meal.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Refeicao',
                    prefixIcon: Icon(Icons.restaurant_outlined),
                  ),
                ),
              ),
              _ResponsiveExpanded(
                flex: 2,
                child: TextField(
                  controller: meal.timeController,
                  decoration: const InputDecoration(
                    labelText: 'Horario',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
              ),
              _IconAction(
                tooltip: 'Remover refeicao',
                onPressed: onRemove,
                icon: Icons.delete_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final food in meal.foods) ...[
            _EditorRow(
              children: [
                _ResponsiveExpanded(
                  flex: 3,
                  child: TextField(
                    controller: food.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Alimento',
                      prefixIcon: Icon(Icons.egg_alt_outlined),
                    ),
                  ),
                ),
                _ResponsiveExpanded(
                  flex: 2,
                  child: TextField(
                    controller: food.quantityController,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                  ),
                ),
                _IconAction(
                  tooltip: 'Remover alimento',
                  onPressed: () => onRemoveFood(food),
                  icon: Icons.close,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddFood,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar alimento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorRow extends StatelessWidget {
  final List<Widget> children;

  const _EditorRow({required this.children});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          for (final child in children) ...[
            child,
            if (child != children.last) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (final child in children) ...[
          child,
          if (child != children.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _ResponsiveExpanded extends StatelessWidget {
  final int flex;
  final Widget child;

  const _ResponsiveExpanded({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return child;
    }

    return Expanded(flex: flex, child: child);
  }
}

class _IconAction extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  const _IconAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );

    if (Responsive.isMobile(context)) {
      return Align(alignment: Alignment.centerRight, child: button);
    }

    return SizedBox(width: 48, child: button);
  }
}

class _MealDraft {
  final String id;
  final TextEditingController nameController;
  final TextEditingController timeController;
  final List<_FoodDraft> foods;

  _MealDraft({
    String? id,
    required String name,
    required String time,
    List<_FoodDraft>? foods,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       nameController = TextEditingController(text: name),
       timeController = TextEditingController(text: time),
       foods = foods ?? [_FoodDraft()];

  factory _MealDraft.fromModel(MealModel meal) {
    return _MealDraft(
      id: meal.id,
      name: meal.name,
      time: meal.time,
      foods: meal.foods.map(_FoodDraft.fromModel).toList(),
    );
  }

  MealModel toModel() {
    return MealModel(
      id: id,
      name: nameController.text.trim(),
      time: timeController.text.trim(),
      foods: foods.map((food) => food.toModel()).toList(),
    );
  }

  void dispose() {
    nameController.dispose();
    timeController.dispose();
    for (final food in foods) {
      food.dispose();
    }
  }
}

class _FoodDraft {
  final String id;
  final TextEditingController nameController;
  final TextEditingController quantityController;

  _FoodDraft({String? id, String name = '', String quantity = ''})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      nameController = TextEditingController(text: name),
      quantityController = TextEditingController(text: quantity);

  factory _FoodDraft.fromModel(FoodItemModel food) {
    return _FoodDraft(id: food.id, name: food.name, quantity: food.quantity);
  }

  FoodItemModel toModel() {
    return FoodItemModel(
      id: id,
      name: nameController.text.trim(),
      quantity: quantityController.text.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}
