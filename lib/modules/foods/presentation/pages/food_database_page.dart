import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../data/models/food_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../patients/presentation/pages/patient_list_page.dart';

class FoodDatabasePage extends StatefulWidget {
  const FoodDatabasePage({super.key});

  @override
  State<FoodDatabasePage> createState() => _FoodDatabasePageState();
}

class _FoodDatabasePageState extends State<FoodDatabasePage> {
  final _repository = FoodRepository();
  final _searchController = TextEditingController();
  late List<FoodModel> _foods;

  @override
  void initState() {
    super.initState();
    _foods = _repository.search('');
    _searchController.addListener(_filterFoods);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterFoods)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _FoodContent(
      foods: _foods,
      searchController: _searchController,
      onAddFood: _addFood,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: Responsive.isDesktop(context)
          ? null
          : AppBar(title: const Text('Banco de alimentos')),
      body: Responsive.isDesktop(context)
          ? Row(
              children: [
                const _FoodSideNavigation(),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  void _filterFoods() {
    setState(() {
      _foods = _repository.search(_searchController.text);
    });
  }

  void _addFood(FoodModel food) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} pronto para adicionar ao plano.')),
    );
  }
}

class _FoodContent extends StatelessWidget {
  final List<FoodModel> foods;
  final TextEditingController searchController;
  final ValueChanged<FoodModel> onAddFood;

  const _FoodContent({
    required this.foods,
    required this.searchController,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      maxWidth: 720,
      child: ListView(
        padding: Responsive.pagePadding(context),
        children: [
          const Text(
            'Banco de alimentos',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10291F),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tabela TACO + cadastros proprios',
            style: TextStyle(color: Color(0xFF66766C)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar alimento...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.green.shade100),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.green.shade100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (foods.isEmpty)
            const _EmptyFoodSearch()
          else
            for (final food in foods) ...[
              _FoodCard(food: food, onAdd: () => onAddFood(food)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onAdd;

  const _FoodCard({required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDE7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF617468),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _FoodMetric(food.portion),
                    _FoodMetric('${food.calories} kcal', isStrong: true),
                    _FoodMetric('P ${food.protein.toStringAsFixed(1)}g'),
                    _FoodMetric('C ${food.carbs.toStringAsFixed(1)}g'),
                    _FoodMetric('G ${food.fat.toStringAsFixed(1)}g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFDDE7E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}

class _FoodMetric extends StatelessWidget {
  final String value;
  final bool isStrong;

  const _FoodMetric(this.value, {this.isStrong = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 12,
        color: isStrong ? Colors.black : const Color(0xFF34483D),
        fontWeight: isStrong ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}

class _FoodSideNavigation extends StatelessWidget {
  const _FoodSideNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFEFC),
        border: Border(right: BorderSide(color: Color(0xFFE6EEE8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _FoodBrand(),
          ),
          const SizedBox(height: 36),
          _SideNavItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            onTap: () => _replaceWith(context, const DashboardPage()),
          ),
          _SideNavItem(
            icon: Icons.book_outlined,
            label: 'Diario',
            onTap: () => _replaceWith(context, const HistoryPage()),
          ),
          _SideNavItem(icon: Icons.auto_awesome, label: 'IA', onTap: () {}),
          _SideNavItem(
            icon: Icons.eco_outlined,
            label: 'Alimentos',
            selected: true,
            onTap: () {},
          ),
          _SideNavItem(
            icon: Icons.person_outline,
            label: 'Perfil',
            onTap: () => _replaceWith(context, const PatientListPage()),
          ),
        ],
      ),
    );
  }

  static void _replaceWith(BuildContext context, Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _FoodBrand extends StatelessWidget {
  const _FoodBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF26C565),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.eco_outlined, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text(
          'Nutri',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF10291F),
          ),
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFE5F2E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF173D2E), size: 22),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF173D2E),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFoodSearch extends StatelessWidget {
  const _EmptyFoodSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDE7)),
      ),
      child: const Text(
        'Nenhum alimento encontrado.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF66766C)),
      ),
    );
  }
}
