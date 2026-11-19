import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog.dart';
import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../../domain/usecases/manage_routine.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart' show errorMessage;
import '../widgets/dosis_widgets.dart';

/// "Adicionar à rotina": lista o que o usuário já usa e busca no catálogo (API ou fake) para adicionar mais.
class RoutinePage extends ConsumerStatefulWidget {
  const RoutinePage({super.key});

  @override
  ConsumerState<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends ConsumerState<RoutinePage> {
  ProductKind _kind = ProductKind.supplement;

  /// Texto da busca já "assentado" (espera o usuário parar de digitar).
  String _search = '';
  Timer? _debounce;

  /// Página do catálogo, começando em 1 (a API conta assim).
  int _page = 1;
  Product? _picked;
  bool _saving = false;
  String? _removingId;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _setKind(ProductKind kind) => setState(() {
        _kind = kind;
        _picked = null;
        _page = 1;
      });

  /// Só consulta o catálogo 350 ms depois da última tecla, para não fazer uma chamada por letra.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
        _picked = null;
      });
    });
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String _describe(Object error) => error is RoutineException ? error.message : errorMessage(error);

  Future<void> _save() async {
    final product = _picked;
    if (product == null) {
      _toast('Escolha um item para adicionar.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(addToRoutineProvider)(productId: product.id);
      // A Home, o "Registrar dose" e esta tela leem o stack daqui: invalidar faz todas recarregarem.
      ref.invalidate(todayStackProvider);
      if (!mounted) return;
      setState(() => _picked = null);
      _toast('${product.name} adicionado à rotina.');
    } catch (error) {
      if (mounted) _toast('Não foi possível adicionar: ${_describe(error)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(RoutineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover da rotina?'),
        content: Text('${item.name} sai do seu stack. As doses já registradas continuam no histórico.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingId = item.id);
    try {
      await ref.read(removeFromRoutineProvider)(item.id);
      ref.invalidate(todayStackProvider);
      if (mounted) _toast('${item.name} removido da rotina.');
    } catch (error) {
      if (mounted) _toast('Não foi possível remover: ${_describe(error)}');
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];
    final mine = all.where((i) => i.kind == _kind).toList();
    // Ids do catálogo que já estão no stack: aparecem marcados e não podem ser escolhidos de novo.
    final inRoutine = <String>{
      for (final item in all)
        if (item.productId != null) item.productId!,
    };
    final isSupplement = _kind == ProductKind.supplement;
    final catalog = ref.watch(catalogSearchProvider((kind: _kind, search: _search, page: _page)));

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
        _MyItems(items: mine, isSupplement: isSupplement, removingId: _removingId, onRemove: _remove),
        const SizedBox(height: 24),
        const SectionTitle('Adicionar outro'),
        const SizedBox(height: 12),
        SearchBox(hint: isSupplement ? 'Pesquisar suplemento' : 'Pesquisar anabolizante', onChanged: _onSearchChanged),
        const SizedBox(height: 16),
        ...catalog.when<List<Widget>>(
          loading: () => const [
            Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
          ],
          error: (error, _) => [
            DosisCard(
              radius: 14,
              child: Column(
                children: [
                  Text('Não foi possível carregar o catálogo: ${_describe(error)}', textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => ref.invalidate(catalogSearchProvider),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
          ],
          data: (result) => _catalogRows(result, inRoutine),
        ),
        if (_picked?.requiresMedicalSupervision ?? false) ...[
          const SizedBox(height: 4),
          DosisCard(
            radius: 14,
            color: AppColors.orangeSoft,
            borderColor: AppColors.orange,
            child: Text(_picked!.caution, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }

  List<Widget> _catalogRows(PageResult<Product> result, Set<String> inRoutine) {
    if (result.results.isEmpty) {
      return [
        DosisCard(
          radius: 14,
          child: Center(
            child: Text(
              _search.isEmpty ? 'Nenhum item no catálogo.' : 'Nada encontrado para "$_search".',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ];
    }
    final pages = (result.count / catalogPageSize).ceil();
    return [
      for (final product in result.results) ...[
        RadioRow(
          label: _label(product, alreadyAdded: inRoutine.contains(product.id)),
          selected: _picked?.id == product.id,
          onTap: () => inRoutine.contains(product.id)
              ? _toast('${product.name} já está na sua rotina.')
              : setState(() => _picked = product),
        ),
        const SizedBox(height: 10),
      ],
      if (pages > 1)
        // O Pager conta a partir de 0; a API, a partir de 1.
        Pager(
          page: _page - 1,
          pages: pages,
          onChanged: (p) => setState(() {
            _page = p + 1;
            _picked = null;
          }),
        ),
    ];
  }

  /// "Creatina monohidratada · 3 g" ou "... · na rotina".
  static String _label(Product product, {required bool alreadyAdded}) {
    if (alreadyAdded) return '${product.name} · na rotina';
    final dose = product.defaultDose;
    return dose == null ? product.name : '${product.name} · ${formatDose(dose, product.defaultUnit, space: true)}';
  }
}

/// Cartão "Seus suplementos"/"Seus anabolizantes" com a lixeira de cada item.
class _MyItems extends StatelessWidget {
  const _MyItems({required this.items, required this.isSupplement, required this.removingId, required this.onRemove});

  final List<RoutineItem> items;
  final bool isSupplement;
  final String? removingId;
  final ValueChanged<RoutineItem> onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return DosisCard(
        radius: 14,
        child: Center(
          child: Text(
            isSupplement ? 'Nenhum suplemento cadastrado' : 'Nenhum anabolizante cadastrado',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }
    return DosisCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          for (final item in items)
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
                      onTap: removingId == null ? () => onRemove(item) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: removingId == item.id
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.delete_outline, color: AppColors.orange, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
