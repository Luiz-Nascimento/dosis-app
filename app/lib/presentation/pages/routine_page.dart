import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_widgets.dart';

/// "Adicionar à rotina". Visual pronto; o catálogo abaixo é fixo até existir o repositório de produtos.
class RoutinePage extends ConsumerStatefulWidget {
  const RoutinePage({super.key});

  @override
  ConsumerState<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends ConsumerState<RoutinePage> {
  static const _catalog = {
    ProductKind.supplement: ['Ômega 3', 'BCAA', 'Hipercalórico', 'Multivitamínico'],
    ProductKind.anabolic: ['Testosterona', 'Nandrolona', 'Oxandrolona', 'Trembolona'],
  };

  ProductKind _kind = ProductKind.supplement;
  String? _picked;
  int _page = 0;

  void _setKind(ProductKind kind) => setState(() {
        _kind = kind;
        _picked = null;
        _page = 0;
      });

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];
    final mine = all.where((i) => i.kind == _kind).toList();
    final isSupplement = _kind == ProductKind.supplement;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Center(
          child: Text('Adicionar à rotina', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        const SectionTitle('O que você utiliza?'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SelectBox(
                label: 'Suplementos',
                selected: isSupplement,
                onTap: () => _setKind(ProductKind.supplement),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectBox(
                label: 'Anabolizantes',
                selected: !isSupplement,
                onTap: () => _setKind(ProductKind.anabolic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionTitle(isSupplement ? 'Seus suplementos' : 'Seus anabolizantes'),
        const SizedBox(height: 12),
        if (mine.isEmpty)
          DosisCard(
            radius: 14,
            child: Center(
              child: Text(
                isSupplement ? 'Nenhum suplemento cadastrado' : 'Nenhum anabolizante cadastrado',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )
        else
          DosisCard(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                for (final item in mine)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.medication_outlined, color: AppColors.yellow, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.brand == null ? item.name : '${item.name} (${item.brand})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Material(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Remover da rotina ainda não está ligado ao repositório.')),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.delete_outline, color: AppColors.orange, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const SectionTitle('Adicionar outro'),
        const SizedBox(height: 12),
        const SearchBox(hint: 'Pesquisar suplemento'),
        const SizedBox(height: 16),
        for (final name in _catalog[_kind]!) ...[
          RadioRow(label: name, selected: _picked == name, onTap: () => setState(() => _picked = name)),
          const SizedBox(height: 10),
        ],
        Pager(page: _page, pages: 4, onChanged: (p) => setState(() => _page = p)),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_picked == null ? 'Escolha um item para adicionar.' : '$_picked selecionado.')),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}