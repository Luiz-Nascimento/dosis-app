import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../../domain/usecases/check_dose_safety.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

class RegisterDosePage extends ConsumerStatefulWidget {
  const RegisterDosePage({super.key});

  @override
  ConsumerState<RegisterDosePage> createState() => _RegisterDosePageState();
}

class _RegisterDosePageState extends ConsumerState<RegisterDosePage> {
  final _dose = TextEditingController();
  String _query = '';
  String? _selectedId;
  Protocol _protocol = Protocol.continuous;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _dose.dispose();
    super.dispose();
  }

  void _select(RoutineItem item) {
    setState(() {
      _selectedId = item.id;
      _protocol = item.protocol;
      _dose.text = item.doseAmount == null ? '' : formatAmount(item.doseAmount!);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  /// Alerta laranja do protótipo com fontes e respaldo científico (KAN-11).
  Future<bool> _confirmHighDose(DoseSafetyCheck check) async {
    final keep = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.black, size: 28),
                  SizedBox(width: 8),
                  Text('Atenção', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                check.message ??
                    'A dose informada está acima da faixa normalmente recomendada.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (check.caution != null) ...[
                const SizedBox(height: 10),
                Text(
                  check.caution!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF202020), fontSize: 12, height: 1.35),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Fonte: ${check.sourcesFormatted}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Revisar Protocolo', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Manter Configuração', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return keep ?? false;
  }

  Future<void> _submit(List<RoutineItem> items) async {
    final item = items.firstWhere((i) => i.id == _selectedId);
    final amount = double.tryParse(_dose.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _toast('Informe uma dose maior que zero.');
      return;
    }

    // Avaliação de segurança com CheckDoseSafety (KAN-11)
    final safetyCheck = ref.read(checkDoseSafetyProvider)(
      productName: item.name,
      amount: amount,
      unit: item.doseUnit,
      protocol: _protocol,
    );

    if (safetyCheck.isAboveRange) {
      if (!await _confirmHighDose(safetyCheck)) return;
    }

    final now = DateTime.now();
    final takenAt = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
    try {
      await ref.read(registerDoseProvider)(routineItemId: item.id, amount: amount, takenAt: takenAt);
      ref.invalidate(doseHistoryProvider);
      if (!mounted) return;
      setState(() => _selectedId = null);
      _toast('Dose registrada.');
    } catch (error) {
      if (mounted) _toast('Não foi possível registrar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];
    final visible = items.where((i) => i.name.toLowerCase().contains(_query.toLowerCase())).toList();
    final selected = items.where((i) => i.id == _selectedId).firstOrNull;

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const PageHeader('Registrar dose'),
          const SizedBox(height: 12),
          const SectionTitle('O que você utilizou?'),
          const SizedBox(height: 12),
          SearchBox(hint: 'Selecionar suplemento', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 24),
          const SectionTitle('Seus itens'),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              for (final item in visible)
                _ItemChip(label: item.name, selected: item.id == _selectedId, onTap: () => _select(item)),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 24),
            const SectionTitle('Protocolo de utilização'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Protocol>(
                  value: _protocol,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.yellow, size: 32),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  items: [
                    for (final p in Protocol.values) DropdownMenuItem(value: p, child: Text(p.label)),
                  ],
                  onChanged: (p) => setState(() => _protocol = p ?? _protocol),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Dose'),
                      const SizedBox(height: 10),
                      DosisCard(
                        radius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dose,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                decoration: const InputDecoration(
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            Text(selected.doseUnit.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Horário'),
                      const SizedBox(height: 10),
                      DosisCard(
                        radius: 14,
                        onTap: _pickTime,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _time.format(context),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            const Icon(Icons.schedule, color: AppColors.yellow, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => _submit(items), child: const Text('Registrar')),
          ],
          const SizedBox(height: 24),
          const SectionTitle('Stack de hoje'),
          const SizedBox(height: 12),
          for (final item in items) ...[
            StackRow(
              time: item.scheduleTimes.isEmpty ? '--:--' : item.scheduleTimes.first,
              name: item.name,
              amount: formatDose(item.doseAmount, item.doseUnit),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.yellow : AppColors.card,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 150,
          height: 76,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}