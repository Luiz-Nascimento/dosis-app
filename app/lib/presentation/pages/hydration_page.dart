import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/tracking.dart';
import '../../domain/usecases/calculate_hydration.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_widgets.dart';

/// Tela de Estimativa de Hidratação.
/// Utiliza o caso de uso [CalculateHydration] (camada de domínio) para estimar
/// a meta de ingestão de água diária com base no peso e no stack de hoje (creatina).
class HydrationPage extends ConsumerStatefulWidget {
  const HydrationPage({super.key});

  @override
  ConsumerState<HydrationPage> createState() => _HydrationPageState();
}

class _HydrationPageState extends ConsumerState<HydrationPage> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  HydrationResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _calculate(List<RoutineItem> items) {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      setState(() {
        _errorMessage = 'Informe um peso válido (ex: 76 kg).';
        _result = null;
      });
      return;
    }

    final calculator = ref.read(calculateHydrationProvider);
    final res = calculator(weightKg: weight, stackItems: items);

    setState(() {
      _errorMessage = null;
      _result = res;
    });
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
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Quanto beber hoje, com base em você e no seu stack',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 24),
        _UnitField(title: 'Peso', controller: _weight, unit: 'kg', hint: '76'),
        const SizedBox(height: 18),
        _UnitField(title: 'Altura', controller: _height, unit: 'cm', hint: '178'),
        const SizedBox(height: 18),
        const SectionTitle('Contexto de hoje', subtitle: 'Suplementos ativos no seu stack'),
        const SizedBox(height: 10),
        DosisCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            children: [
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nenhum item ativo no stack hoje', style: TextStyle(color: AppColors.muted)),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      Text(
                        formatDose(item.doseAmount, item.doseUnit, space: true),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFFCFCFD4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => _calculate(items),
          child: const Text('Calcular estimativa'),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          DosisCard(
            borderColor: AppColors.orange,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 20),
          _ResultCard(result: _result!),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final HydrationResult result;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'META RECOMENDADA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.totalLitersText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${result.totalMl} ml / dia',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            result.explanation,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFFE2E2E2),
            ),
          ),
          if (result.creatineBonusMl > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, size: 18, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+${result.creatineBonusMl} ml pelo uso de creatina (margem preventiva do app)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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