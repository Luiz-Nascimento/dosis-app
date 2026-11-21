import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/tracking.dart';
import '../../domain/usecases/edit_day_records.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Abre "Editar stack do dia". Devolve `true` se salvou.
Future<bool?> showEditDayStackSheet(
  BuildContext context, {
  required String localDate,
  required List<DoseLog> doses,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => EditDayStackSheet(localDate: localDate, doses: doses),
    );

class _DoseRow {
  _DoseRow({this.original, this.item, required this.time, required String amount})
      : amount = TextEditingController(text: amount);

  final DoseLog? original;

  /// `null` mantém o produto original da dose.
  RoutineItem? item;
  TimeOfDay time;
  final TextEditingController amount;
}

class EditDayStackSheet extends ConsumerStatefulWidget {
  const EditDayStackSheet({super.key, required this.localDate, required this.doses});

  final String localDate;
  final List<DoseLog> doses;

  @override
  ConsumerState<EditDayStackSheet> createState() => _EditDayStackSheetState();
}

class _EditDayStackSheetState extends ConsumerState<EditDayStackSheet> {
  static const _keep = '__original__';
  static const _fieldColor = Color(0xFF1D1D1F);

  late final List<_DoseRow> _rows = [
    for (final dose in widget.doses)
      _DoseRow(
        original: dose,
        time: TimeOfDay.fromDateTime(dose.takenAt.toLocal()),
        amount: formatAmount(dose.amount),
      ),
  ];
  final List<_DoseRow> _removed = [];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final row in [..._rows, ..._removed]) {
      row.amount.dispose();
    }
    super.dispose();
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _name(_DoseRow row) => row.item?.name ?? row.original?.name ?? '';

  String _unit(_DoseRow row) => (row.item?.doseUnit ?? row.original?.unit)?.label ?? '';

  /// Valor selecionado no menu: o item escolhido, o item original (se ainda está no stack) ou "manter".
  String _value(_DoseRow row, List<RoutineItem> stack) {
    if (row.item != null) return row.item!.id;
    final original = row.original;
    if (original != null && stack.any((i) => i.id == original.routineItemId)) return original.routineItemId!;
    return _keep;
  }

  List<DropdownMenuItem<String>> _menu(_DoseRow row, List<RoutineItem> stack) {
    final items = [
      for (final item in stack)
        DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis)),
    ];
    final original = row.original;
    if (original != null && !stack.any((i) => i.id == original.routineItemId)) {
      items.insert(0, DropdownMenuItem(value: _keep, child: Text(original.name, overflow: TextOverflow.ellipsis)));
    }
    return items;
  }

  Future<void> _pickTime(_DoseRow row) async {
    final picked = await showTimePicker(context: context, initialTime: row.time);
    if (picked != null) setState(() => row.time = picked);
  }

  void _add() {
    final stack = ref.read(todayStackProvider).value ?? const <RoutineItem>[];
    if (stack.isEmpty) {
      setState(() => _error = 'Adicione um item à rotina antes de incluir doses.');
      return;
    }
    final item = stack.first;
    setState(() {
      _error = null;
      _rows.add(_DoseRow(item: item, time: TimeOfDay.now(), amount: formatAmount(item.doseAmount ?? 1)));
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final parts = widget.localDate.split('-').map(int.parse).toList();
      final drafts = <DoseDraft>[];
      for (final row in _rows) {
        final amount = double.tryParse(row.amount.text.trim().replaceAll(',', '.'));
        if (amount == null) throw ArgumentError('Informe a dose de ${_name(row)}.');
        drafts.add(DoseDraft(
          id: row.original?.id,
          item: row.item,
          amount: amount,
          takenAt: DateTime(parts[0], parts[1], parts[2], row.time.hour, row.time.minute),
        ));
      }
      await ref.read(saveDayStackProvider)(original: widget.doses, drafts: drafts);
      ref.invalidate(doseHistoryProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _error = '${error.message}');
    } on ApiException catch (error) {
      ref.invalidate(doseHistoryProvider);
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      ref.invalidate(doseHistoryProvider);
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _rowWidget(_DoseRow row, List<RoutineItem> stack) {
    return Row(
      children: [
        InkWell(
          onTap: () => _pickTime(row),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            decoration: BoxDecoration(color: _fieldColor, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_two(row.time.hour)}:${_two(row.time.minute)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.schedule, size: 14, color: AppColors.yellow),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: _fieldColor, borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _value(row, stack),
                isExpanded: true,
                dropdownColor: AppColors.card,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.yellow),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                items: _menu(row, stack),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => row.item = value == _keep ? null : stack.firstWhere((i) => i.id == value));
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 86,
          child: TextField(
            controller: row.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              suffixText: _unit(row),
              suffixStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() {
            _rows.remove(row);
            _removed.add(row);
          }),
          icon: const Icon(Icons.delete_outline, color: AppColors.orange, size: 22),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stack = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Editar stack do dia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              if (_rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Nenhuma dose neste dia.', style: TextStyle(color: AppColors.muted)),
                ),
              for (final row in _rows)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: _rowWidget(row, stack)),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar dose'),
                ),
              ),
              AuthError(_error),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: AuthButton(label: 'Salvar alterações', busy: _saving, onPressed: _save),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}