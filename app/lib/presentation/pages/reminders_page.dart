import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/settings.dart';
import '../../data/models/tracking.dart';
import '../../domain/usecases/update_settings.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

/// "Lembretes": liga e ajusta as notificações de água e de suplementos.
class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  static const _intervals = [1, 2, 3, 4];

  /// Rascunho editado na tela; só vale depois de "Salvar".
  UserSettings? _draft;
  bool _saving = false;

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _pickHour(UserSettings draft, {required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ? draft.waterStartHour : draft.waterEndHour, minute: 0),
      helpText: start ? 'Primeiro lembrete (hora cheia)' : 'Último lembrete (hora cheia)',
    );
    if (picked == null) return;
    setState(() {
      _draft = start ? draft.copyWith(waterStartHour: picked.hour) : draft.copyWith(waterEndHour: picked.hour);
    });
  }

  Future<void> _save(UserSettings draft) async {
    setState(() => _saving = true);
    try {
      final update = await ref.read(settingsProvider.notifier).save(draft);
      if (!mounted) return;
      setState(() => _draft = update.settings);
      _toast(update.permissionDenied
          ? 'Sem permissão de notificações: os lembretes ficaram desligados. Libere nas configurações do aparelho.'
          : update.settings.anyReminder
              ? 'Lembretes salvos.'
              : 'Lembretes desligados.');
    } on ArgumentError catch (error) {
      if (mounted) _toast('${error.message}');
    } catch (error) {
      if (mounted) _toast('Não foi possível salvar: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(settingsProvider).value;
    final items = ref.watch(todayStackProvider).value ?? const <RoutineItem>[];
    final draft = _draft ?? saved;

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: draft == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const PageHeader('Lembretes'),
                const SizedBox(height: 16),
                _SwitchCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Lembretes de água',
                  subtitle: 'Avisos ao longo do dia para bater a meta',
                  value: draft.waterReminders,
                  onChanged: (v) => setState(() => _draft = draft.copyWith(waterReminders: v)),
                ),
                if (draft.waterReminders) ...[
                  const SizedBox(height: 16),
                  const Text('Lembrar a cada', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final hours in _intervals) ...[
                        Expanded(
                          child: SelectBox(
                            label: '$hours h',
                            height: 44,
                            selected: draft.waterIntervalHours == hours,
                            onTap: () => setState(() => _draft = draft.copyWith(waterIntervalHours: hours)),
                          ),
                        ),
                        if (hours != _intervals.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HourField(
                          label: 'Das',
                          hour: draft.waterStartHour,
                          onTap: () => _pickHour(draft, start: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HourField(
                          label: 'Até',
                          hour: draft.waterEndHour,
                          onTap: () => _pickHour(draft, start: false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _SwitchCard(
                  icon: Icons.medication_outlined,
                  title: 'Lembretes de suplementos',
                  subtitle: 'Avisos nos horários dos itens da sua rotina',
                  value: draft.supplementReminders,
                  onChanged: (v) => setState(() => _draft = draft.copyWith(supplementReminders: v)),
                ),
                const SizedBox(height: 22),
                const SectionTitle('O que você vai receber', subtitle: 'Todos os dias, nestes horários'),
                const SizedBox(height: 12),
                _Preview(draft: draft, items: items),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(draft),
                  child: const Text('Salvar lembretes'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Os lembretes são notificações do próprio aparelho e funcionam sem internet. '
                  'O Android pode atrasar alguns minutos para economizar bateria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
    );
  }
}

/// Lista o que seria agendado com o rascunho atual, usando a mesma regra do caso de uso.
class _Preview extends StatelessWidget {
  const _Preview({required this.draft, required this.items});

  final UserSettings draft;
  final List<RoutineItem> items;

  static String _time(Reminder r) => '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final valid = draft.waterStartHour <= draft.waterEndHour;
    final reminders = valid ? planReminders(draft, items) : const <Reminder>[];
    final water = reminders.where((r) => r.kind == ReminderKind.water).toList();
    final supplements = reminders.where((r) => r.kind == ReminderKind.supplement).toList();

    String? message;
    if (!valid) {
      message = 'O horário inicial precisa vir antes do final.';
    } else if (!draft.anyReminder) {
      message = 'Nenhum lembrete ligado.';
    } else if (reminders.isEmpty) {
      message = 'Nenhum item ativo da rotina tem horário definido.';
    }

    return DosisCard(
      borderColor: valid ? AppColors.border : AppColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) Text(message, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          if (water.isNotEmpty) ...[
            Text(
              'Água: ${water.length} ${water.length == 1 ? 'lembrete' : 'lembretes'}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(water.map(_time).join('  ·  '), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
          if (water.isNotEmpty && supplements.isNotEmpty) const SizedBox(height: 12),
          for (final reminder in supplements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _time(reminder),
                    style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reminder.body.split('. ').first,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          if (draft.supplementReminders && valid && supplements.isEmpty && water.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Suplementos: nenhum item ativo da rotina tem horário definido.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(icon, color: AppColors.yellow, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.black, activeTrackColor: AppColors.yellow),
        ],
      ),
    );
  }
}

class _HourField extends StatelessWidget {
  const _HourField({required this.label, required this.hour, required this.onTap});

  final String label;
  final int hour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      radius: 14,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${hour.toString().padLeft(2, '0')}:00', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const Icon(Icons.schedule, color: AppColors.yellow, size: 18),
        ],
      ),
    );
  }
}
