import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/tracking.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_widgets.dart';

/// "Estimativa de hidratação". A conta é provisória (35 ml por kg, +500 ml com creatina):
/// a regra final fica com a tarefa da calculadora.
class HydrationPage extends ConsumerStatefulWidget {
  const HydrationPage({super.key});

  @override
  ConsumerState<HydrationPage> createState() => _HydrationPageState();
}

class _HydrationPageState extends ConsumerState<HydrationPage> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  String? _result;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _calculate(List<RoutineItem> items) {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      setState(() => _result = 'Informe seu peso para calcular.');
      return;
    }
    var ml = weight * 35;
    if (items.any((i) => i.name.toLowerCase().contains('creatina'))) ml += 500;
    final liters = (ml / 1000).toStringAsFixed(1).replaceAll('.', ',');
    setState(() => _result = 'Cerca de $liters L de água hoje.');
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Center(
          child: Text('Estimativa de hidratação', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        const Center(
          child: Text(
            'Quanto beber hoje, com base em você e no seu stack',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 24),
        _UnitField(title: 'Peso', controller: _weight, unit: 'kg', hint: '76'),
        const SizedBox(height: 18),
        _UnitField(title: 'Altura', controller: _height, unit: 'cm', hint: '178'),
        const SizedBox(height: 18),
        const SectionTitle('Contexto de hoje'),
        const SizedBox(height: 10),
        DosisCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            children: [
              if (items.isEmpty) const Text('Nenhum item no stack', style: TextStyle(color: AppColors.muted)),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                      Text(
                        formatDose(item.doseAmount, item.doseUnit, space: true),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFCFCFD4)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => _calculate(items), child: const Text('Calcular estimativa')),
        if (_result != null) ...[
          const SizedBox(height: 16),
          DosisCard(
            child: Center(
              child: Text(_result!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({required this.title, required this.controller, required this.unit, required this.hint});

  final String title;
  final TextEditingController controller;
  final String unit;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        const SizedBox(height: 10),
        DosisCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              Text(unit, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}